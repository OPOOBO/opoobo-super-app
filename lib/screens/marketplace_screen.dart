import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../services/market_service.dart';
import '../utils/navigation.dart';
import '../widgets/market_item_card.dart';
import '../widgets/screen_header.dart';
import 'market_chat_list_screen.dart';
import 'market_detail_screen.dart';
import 'market_saved_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final MarketService _market = MarketService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<dynamic> _items = [];
  List<dynamic> _categories = [];
  Set<int> _favIds = {};
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int? _selectedCategoryId;
  bool _featuredOnly = false;
  int _page = 1;
  int _lastPage = 1;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 400 &&
        !_loading &&
        !_loadingMore &&
        _page < _lastPage) {
      _loadMore();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
      _page = 1;
    });
    try {
      final results = await Future.wait([
        _market.getItems(filters: _itemFilters(page: 1)),
        _market.getCategories(),
        _market.getFavourites(),
      ]);
      if (!mounted) return;
      final paged = _parsePaged(results[0]);
      setState(() {
        _items = paged['items'] as List<dynamic>;
        _lastPage = paged['lastPage'] as int;
        _categories = _parseList(results[1]);
        _favIds = _parseIds(results[2]);
        if (_items.isEmpty && results[0] == null) {
          _error = 'Could not load items. Check your connection and retry.';
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load. Pull to retry.';
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      final res = await _market.getItems(
        filters: _itemFilters(page: _page + 1),
      );
      if (!mounted) return;
      final paged = _parsePaged(res);
      setState(() {
        _items.addAll(paged['items'] as List<dynamic>);
        _lastPage = paged['lastPage'] as int;
        _page = _page + 1;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  Map<String, dynamic> _itemFilters({required int page}) {
    return {
      'limit': _pageSize,
      'page': page,
      // Upstream 'featured' = approved + actively promoted items.
      'status': _featuredOnly ? 'featured' : 'approved',
      if (_selectedCategoryId != null && !_featuredOnly)
        'category_id': _selectedCategoryId,
    };
  }

  void _selectCategory(int? id) {
    if (_selectedCategoryId == id && !_featuredOnly) return;
    setState(() {
      _selectedCategoryId = id;
      _featuredOnly = false;
    });
    _loadData();
  }

  void _toggleFeatured() {
    setState(() {
      _featuredOnly = !_featuredOnly;
      if (_featuredOnly) _selectedCategoryId = null;
    });
    _loadData();
  }

  /// Paginated shape: {data: {data: [...], last_page, total, ...}}
  Map<String, dynamic> _parsePaged(Map<String, dynamic>? res) {
    if (res == null) return {'items': <dynamic>[], 'lastPage': 1};
    final d = res['data'];
    if (d is Map) {
      final inner = d['data'];
      if (inner is List) {
        return {
          'items': inner,
          'lastPage': (d['last_page'] as num?)?.toInt() ?? 1,
        };
      }
    }
    return {'items': _parseList(res), 'lastPage': 1};
  }

  /// Favourite ids from the server list — same table the main app reads.
  Set<int> _parseIds(Map<String, dynamic>? res) {
    if (!marketSuccess(res)) return {};
    final ids = <int>{};
    for (final e in _parseList(res)) {
      if (e is Map && e['id'] != null) ids.add((e['id'] as num).toInt());
    }
    return ids;
  }

  /// Upstream shapes vary ({data: [...]}, {data: {data: [...]}}, {data: {items: [...]}})
  List<dynamic> _parseList(Map<String, dynamic>? res) {
    if (res == null) return [];
    final d = res['data'];
    if (d is List) return d;
    if (d is Map) {
      final inner = d['data'] ?? d['items'] ?? d['categories'] ?? d['result'];
      if (inner is List) return inner;
    }
    return [];
  }

  Future<void> _search() async {
    final q = _searchController.text.trim();
    if (q.isEmpty) {
      if (_selectedCategoryId != null) {
        setState(() => _selectedCategoryId = null);
      }
      _loadData();
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _market.search(q);
    if (!mounted) return;
    setState(() {
      _items = _parseList(result);
      _lastPage = 1;
      _page = 1;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: Column(
        children: [
          ScreenHeader(
            title: 'Marketplace',
            subtitle: 'Buy & sell locally',
            action: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () =>
                      NavigationHelper.push(context, const MarketSavedScreen()),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurface
                          : AppColors.secondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.favorite_border_rounded,
                      size: 18,
                      color: isDark
                          ? AppColors.darkForeground
                          : AppColors.foreground,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => NavigationHelper.push(
                    context,
                    const MarketChatListScreen(),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurface
                          : AppColors.secondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 18,
                      color: isDark
                          ? AppColors.darkForeground
                          : AppColors.foreground,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'Search items...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: isDark ? AppColors.darkSurface : AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length + 2,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                if (i == 0) {
                  return GestureDetector(
                    onTap: _toggleFeatured,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: _featuredOnly
                            ? AppColors.gradientPrimary
                            : null,
                        color: _featuredOnly
                            ? null
                            : Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: _featuredOnly
                            ? null
                            : Border.all(
                                color: Colors.amber.withValues(alpha: 0.4),
                              ),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: _featuredOnly
                                ? Colors.white
                                : Colors.amber[800],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Featured',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _featuredOnly
                                  ? Colors.white
                                  : (isDark
                                        ? AppColors.darkForeground
                                        : AppColors.foreground),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (i == 1)
                  return _categoryChip(
                    label: 'All',
                    selected: _selectedCategoryId == null && !_featuredOnly,
                    isDark: isDark,
                    onTap: () => _selectCategory(null),
                  );
                final cat = _categories[i - 2] as Map<String, dynamic>;
                final id = (cat['id'] as num?)?.toInt();
                final name = (cat['translated_name'] ?? cat['name'] ?? '')
                    .toString();
                return _categoryChip(
                  label: name,
                  selected: _selectedCategoryId == id && id != null,
                  isDark: isDark,
                  onTap: () => _selectCategory(id),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null && _items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _items.isEmpty
                ? RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView(
                      children: const [
                        SizedBox(height: 80),
                        Center(child: Text('No items yet. Pull to refresh.')),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: GridView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.68,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: _items.length + (_loadingMore ? 2 : 0),
                      itemBuilder: (ctx, i) {
                        if (i >= _items.length) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final m = Map<String, dynamic>.from(_items[i] as Map);
                        final id = (m['id'] as num?)?.toInt();
                        return MarketItemCard(
                          item: m,
                          favourited: id != null && _favIds.contains(id),
                          onFavouriteChanged: (favId, fav) {
                            setState(() {
                              if (fav) {
                                _favIds.add(favId);
                              } else {
                                _favIds.remove(favId);
                              }
                            });
                          },
                          onTap: () => NavigationHelper.push(
                            context,
                            MarketDetailScreen(item: m),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _categoryChip({
    required String label,
    required bool selected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.gradientPrimary : null,
          color: selected
              ? null
              : (isDark ? AppColors.darkSurface : AppColors.surface),
          borderRadius: BorderRadius.circular(20),
          border: selected
              ? null
              : Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected
                ? Colors.white
                : (isDark ? AppColors.darkForeground : AppColors.foreground),
          ),
        ),
      ),
    );
  }
}

/// Item cards now live in widgets/market_item_card.dart (shared with Saved).
