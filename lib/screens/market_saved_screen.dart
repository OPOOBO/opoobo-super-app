import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/market_service.dart';
import '../utils/navigation.dart';
import '../widgets/market_item_card.dart';
import '../widgets/screen_header.dart';
import 'market_detail_screen.dart';

/// Items the user hearted — reads the same market `favourites` table as
/// the main market app, so both stay in sync automatically.
class MarketSavedScreen extends StatefulWidget {
  const MarketSavedScreen({super.key});

  @override
  State<MarketSavedScreen> createState() => _MarketSavedScreenState();
}

class _MarketSavedScreenState extends State<MarketSavedScreen> {
  final MarketService _market = MarketService();
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _market.getFavourites();
      if (!mounted) return;
      setState(() {
        _items = _parseList(res);
        if (_items.isEmpty && !marketSuccess(res)) {
          _error = 'Could not load saved items. Check your connection.';
        }
        _loading = false;
      });
    } catch (_) {
      if (mounted)
        setState(() {
          _error = 'Failed to load saved items.';
          _loading = false;
        });
    }
  }

  List<dynamic> _parseList(Map<String, dynamic>? res) {
    if (!marketSuccess(res)) return [];
    final d = res!['data'];
    if (d is List) return d;
    if (d is Map && d['data'] is List) return d['data'];
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: Column(
        children: [
          const ScreenHeader(
            title: 'Saved items',
            subtitle: 'Synced with OPOOBO Market',
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
                          onPressed: _load,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _items.isEmpty
                ? RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      children: const [
                        SizedBox(height: 80),
                        Center(
                          child: Text(
                            'Nothing saved yet.\nTap the heart on any item.',
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.68,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: _items.length,
                      itemBuilder: (ctx, i) {
                        final m = Map<String, dynamic>.from(_items[i] as Map);
                        return MarketItemCard(
                          item: m,
                          favourited: true,
                          onFavouriteChanged: (favId, fav) {
                            if (!fav) {
                              setState(
                                () => _items.removeWhere(
                                  (e) =>
                                      (e is Map &&
                                      (e['id'] as num?)?.toInt() == favId),
                                ),
                              );
                            }
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
}
