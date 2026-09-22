import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../providers/module_provider.dart';
import '../services/market_service.dart';
import '../screens/bus_module_screen.dart';
import '../screens/jobs_screen.dart';
import '../screens/market_detail_screen.dart';
import '../utils/navigation.dart';
import '../widgets/screen_header.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final MarketService _market = MarketService();
  String _source = 'All';
  String _query = '';
  Timer? _debounce;
  bool _searching = false;
  List<dynamic> _marketItems = [];
  List<dynamic> _jobs = [];

  final List<String> _suggestions = [
    'Camry',
    'Bags',
    'iPhone',
    'Sofa',
    'Bus trips',
    'Jobs',
  ];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String v) {
    setState(() => _query = v);
    _debounce?.cancel();
    final q = v.trim();
    if (q.length < 2) {
      setState(() {
        _marketItems = [];
        _jobs = [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 600), () => _runSearch(q));
  }

  /// One query, every service in parallel. New services (Mall, …) plug in
  /// here as one more source entry — each result carries its source tag.
  Future<void> _runSearch(String q) async {
    try {
      final results = await Future.wait([_market.search(q), _market.getJobs()]);
      if (!mounted) return;
      final needle = q.toLowerCase();
      final jobs = _parseList(results[1]).where((j) {
        if (j is! Map) return false;
        final hay =
            '${j['name'] ?? ''} ${j['title'] ?? ''} ${j['company'] ?? ''} '
            '${j['seller'] is Map ? (j['seller']['name'] ?? '') : ''}';
        return hay.toLowerCase().contains(needle);
      }).toList();
      setState(() {
        _marketItems = _parseList(results[0]);
        _jobs = jobs;
        _searching = false;
      });
    } catch (_) {
      if (mounted) setState(() => _searching = false);
    }
  }

  List<dynamic> _parseList(Map<String, dynamic>? res) {
    if (res == null) return [];
    final d = res['data'];
    if (d is List) return d;
    if (d is Map) {
      final inner = d['data'] ?? d['items'] ?? d['result'];
      if (inner is List) return inner;
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: isDark ? AppColors.darkBackground : AppColors.background,
        child: Column(
          children: [
            const ScreenHeader(title: 'Search', subtitle: 'Services and trips'),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.glassStrong,
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: isDark
                          ? AppColors.darkMutedForeground
                          : AppColors.mutedForeground,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        autofocus: true,
                        onChanged: _onQueryChanged,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.darkForeground
                              : AppColors.foreground,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Search everything...',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.darkMutedForeground
                                : AppColors.mutedForeground,
                          ),
                        ),
                      ),
                    ),
                    if (_query.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _controller.clear();
                          _onQueryChanged('');
                        },
                        child: Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: isDark
                              ? AppColors.darkMutedForeground
                              : AppColors.mutedForeground,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: ['All', 'Market', 'Jobs'].map((s) {
                  final isActive = _source == s;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _source = s),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: isActive ? AppColors.gradientPrimary : null,
                          color: isActive
                              ? null
                              : (isDark
                                    ? AppColors.darkSurface
                                    : AppColors.secondary),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          s,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isActive
                                ? Colors.white
                                : (isDark
                                      ? AppColors.darkForeground
                                      : AppColors.foreground),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _query.isEmpty
                  ? _buildSuggestions(isDark)
                  : _buildResults(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Suggested',
            style: GoogleFonts.sora(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkForeground : AppColors.foreground,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions.map((s) {
              return GestureDetector(
                onTap: () {
                  _controller.text = s;
                  _onQueryChanged(s);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkGlass : AppColors.glass,
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkGlassBorder
                          : AppColors.glassBorder,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    s,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkForeground
                          : AppColors.foreground,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(bool isDark) {
    final modules = context.watch<ModuleProvider>().modules;
    final filtered = modules.where((m) {
      if (_query.isNotEmpty &&
          !m.displayName.toLowerCase().contains(_query.toLowerCase()) &&
          !(m.description ?? '').toLowerCase().contains(_query.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

    final showMarket =
        (_source == 'All' || _source == 'Market') && _query.trim().length >= 2;
    final showJobs =
        (_source == 'All' || _source == 'Jobs') && _query.trim().length >= 2;
    final marketHits = showMarket ? _marketItems : <dynamic>[];
    final jobHits = showJobs ? _jobs : <dynamic>[];
    final hasAnything =
        filtered.isNotEmpty ||
        marketHits.isNotEmpty ||
        jobHits.isNotEmpty ||
        _searching;

    if (!hasAnything && _query.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: isDark
                  ? AppColors.darkMutedForeground
                  : AppColors.mutedForeground,
            ),
            const SizedBox(height: 12),
            Text(
              'No results for "$_query"',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkMutedForeground
                    : AppColors.mutedForeground,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (filtered.isNotEmpty) ...[
            Text(
              'Services',
              style: GoogleFonts.sora(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.darkForeground : AppColors.foreground,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 0.85,
              children: filtered
                  .map((m) => _SearchModuleTile(module: m, isDark: isDark))
                  .toList(),
            ),
            const SizedBox(height: 8),
          ],
          if (_searching) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: CircularProgressIndicator(),
              ),
            ),
          ],
          if (marketHits.isNotEmpty) ...[
            _sectionTitle('Market', isDark),
            const SizedBox(height: 8),
            ...marketHits.take(6).map((raw) {
              final m = Map<String, dynamic>.from(raw as Map);
              final title = (m['translated_name'] ?? m['name'] ?? '')
                  .toString();
              final price = (m['formatted_price'] ?? m['price'] ?? '')
                  .toString();
              final image = (m['image'] ?? '').toString();
              return _ContentRow(
                isDark: isDark,
                imageUrl: image,
                fallbackIcon: Icons.shopping_cart_rounded,
                title: title,
                subtitle: price,
                sourceLabel: 'Market',
                sourceColor: AppColors.primary,
                onTap: () =>
                    NavigationHelper.push(context, MarketDetailScreen(item: m)),
              );
            }),
          ],
          if (jobHits.isNotEmpty) ...[
            _sectionTitle('Jobs', isDark),
            const SizedBox(height: 8),
            ...jobHits.take(6).map((raw) {
              final j = Map<String, dynamic>.from(raw as Map);
              final title = (j['name'] ?? j['title'] ?? '').toString();
              final company =
                  (j['seller'] is Map
                          ? (j['seller']['name'] ?? '')
                          : (j['company'] ?? ''))
                      .toString();
              return _ContentRow(
                isDark: isDark,
                imageUrl: '',
                fallbackIcon: Icons.work_outline_rounded,
                title: title,
                subtitle: company,
                sourceLabel: 'Jobs',
                sourceColor: AppColors.success,
                onTap: () => NavigationHelper.push(context, const JobsScreen()),
              );
            }),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        t,
        style: GoogleFonts.sora(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: isDark ? AppColors.darkForeground : AppColors.foreground,
        ),
      ),
    );
  }
}

class _ContentRow extends StatelessWidget {
  final bool isDark;
  final String imageUrl;
  final IconData fallbackIcon;
  final String title;
  final String subtitle;
  final String sourceLabel;
  final Color sourceColor;
  final VoidCallback? onTap;

  const _ContentRow({
    required this.isDark,
    required this.imageUrl,
    required this.fallbackIcon,
    required this.title,
    required this.subtitle,
    required this.sourceLabel,
    required this.sourceColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.muted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            Icon(fallbackIcon, color: AppColors.primary),
                      ),
                    )
                  : Icon(fallbackIcon, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: sourceColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                sourceLabel,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: sourceColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchModuleTile extends StatelessWidget {
  final ModuleData module;
  final bool isDark;

  const _SearchModuleTile({required this.module, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isLinked = module.isLinked;
    final isComingSoon = !module.isActive;

    return GestureDetector(
      onTap: () {
        if (module.name == 'bus') {
          NavigationHelper.push(context, const BusModuleScreen());
        } else if (isComingSoon) {
          final url = module.websiteUrl ?? 'https://opoobo.com';
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Text('${module.displayName} is coming soon'),
              content: Text('Visit us at $url'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkGlass : AppColors.glass,
          border: Border.all(
            color: isDark ? AppColors.darkGlassBorder : AppColors.glassBorder,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _getIcon(module.name),
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const Spacer(),
                if (isComingSoon)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Soon',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.warningForeground,
                      ),
                    ),
                  )
                else if (isLinked)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Linked',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              module.displayName,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.darkForeground : AppColors.foreground,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              module.description ?? '',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.darkMutedForeground
                    : AppColors.mutedForeground,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(String name) {
    switch (name) {
      case 'bus':
        return Icons.directions_bus_rounded;
      case 'market':
        return Icons.shopping_cart_rounded;
      case 'go':
        return Icons.directions_car_rounded;
      case 'mall':
        return Icons.storefront_rounded;
      default:
        return Icons.apps_rounded;
    }
  }
}
