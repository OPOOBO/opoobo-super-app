import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/module_api_client.dart';
import '../providers/module_provider.dart';
import '../theme/app_colors.dart';
import '../screens/mini_app_detail_screen.dart';
import '../utils/navigation.dart';
import '../widgets/screen_header.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  final ModuleApiClient _api = ModuleApiClient();
  List<ModuleData> _apps = [];
  List<String> _categories = [];
  String? _selectedCategory;
  String _search = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStore();
  }

  Future<void> _loadStore() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.storeBrowse(
        category: _selectedCategory,
        query: _search.isNotEmpty ? _search : null,
      );
      if (res['success'] == true) {
        final data = res['data'];
        setState(() {
          _apps = (data['apps'] as List<dynamic>? ?? [])
              .map((a) => ModuleData.fromJson(a))
              .toList();
          _categories = List<String>.from(data['categories'] ?? []);
          _loading = false;
        });
      } else {
        setState(() {
          _error = res['message'] ?? 'Failed to load store';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Cannot connect to store';
        _loading = false;
      });
    }
  }

  List<ModuleData> get _featured => _apps.where((a) => a.isFeatured).toList();
  List<ModuleData> get _filtered {
    var list = _apps.where((a) => !a.isFeatured).toList();
    if (_selectedCategory != null) {
      list = list.where((a) => a.category == _selectedCategory).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: Column(
        children: [
          ScreenHeader(
            title: 'Store',
            subtitle: 'Discover mini-apps for OPOOBO.',
            showBack: false,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.glass,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_outlined,
                    size: 18,
                    color: isDark
                        ? AppColors.darkMutedForeground
                        : AppColors.mutedForeground,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      onChanged: (v) {
                        setState(() => _search = v);
                        _loadStore();
                      },
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.darkForeground
                            : AppColors.foreground,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Search apps...',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.darkMutedForeground
                              : AppColors.mutedForeground,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_categories.isNotEmpty)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                children: [
                  _CategoryChip(
                    label: 'All',
                    isActive: _selectedCategory == null,
                    isDark: isDark,
                    onTap: () {
                      setState(() => _selectedCategory = null);
                      _loadStore();
                    },
                  ),
                  ..._categories.map(
                    (c) => _CategoryChip(
                      label: c,
                      isActive: _selectedCategory == c,
                      isDark: isDark,
                      onTap: () {
                        setState(() => _selectedCategory = c);
                        _loadStore();
                      },
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _error != null
                ? _buildError(isDark)
                : _buildContent(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildError(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 48,
            color: isDark
                ? AppColors.darkMutedForeground
                : AppColors.mutedForeground,
          ),
          const SizedBox(height: 12),
          Text(
            _error!,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark
                  ? AppColors.darkMutedForeground
                  : AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(onPressed: _loadStore, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    if (_apps.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.storefront_outlined,
              size: 48,
              color: isDark
                  ? AppColors.darkMutedForeground
                  : AppColors.mutedForeground,
            ),
            const SizedBox(height: 12),
            Text(
              'No apps yet',
              style: GoogleFonts.inter(
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

    final hasFeatured = _featured.isNotEmpty;
    final allItems = _filtered;

    // Get installed mini-apps from the module provider
    final installedMiniApps = context.read<ModuleProvider>().linkedModules
        .where((m) => m.isMiniApp)
        .toList();

    return RefreshIndicator(
      onRefresh: _loadStore,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          // Installed apps section
          if (installedMiniApps.isNotEmpty) ...[
            Text(
              'Your Apps',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? AppColors.darkForeground
                    : AppColors.foreground,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: installedMiniApps.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, i) => _InstalledAppCard(
                  app: installedMiniApps[i],
                  isDark: isDark,
                  onTap: () => _openApp(installedMiniApps[i]),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          if (hasFeatured) ...[
            Text(
              'Featured',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? AppColors.darkForeground
                    : AppColors.foreground,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _featured.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, i) => _FeaturedCard(
                  app: _featured[i],
                  isDark: isDark,
                  onTap: () => _openApp(_featured[i]),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          Text(
            'All Apps',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: isDark
                  ? AppColors.darkForeground
                  : AppColors.foreground,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: allItems.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.85,
            ),
            itemBuilder: (_, i) => _AppCard(
              app: allItems[i],
              isDark: isDark,
              onTap: () => _openApp(allItems[i]),
            ),
          ),
        ],
      ),
    );
  }

  void _openApp(ModuleData app) {
    // Navigate to detail screen instead of directly to WebView
    NavigationHelper.push(context, MiniAppDetailScreen(module: app));
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: isActive ? AppColors.gradientPrimary : null,
            color: isActive
                ? null
                : (isDark ? AppColors.darkSurface : AppColors.secondary),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isActive
                  ? Colors.white
                  : (isDark ? AppColors.darkForeground : AppColors.foreground),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final ModuleData app;
  final bool isDark;
  final VoidCallback onTap;

  const _FeaturedCard({
    required this.app,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppColors.gradientPrimary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFeaturedIcon(app),
            const Spacer(),
            Text(
              app.displayName,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              app.description ?? '',
              style: GoogleFonts.inter(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _AppCard extends StatelessWidget {
  final ModuleData app;
  final bool isDark;
  final VoidCallback onTap;

  const _AppCard({
    required this.app,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkGlass : AppColors.glass,
          border: Border.all(
            color: isDark ? AppColors.darkGlassBorder : AppColors.glassBorder,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
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
                _buildIcon(app, 42, 12),
                const Spacer(),
                if (app.isFeatured)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '\u2605',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              app.displayName,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.darkForeground : AppColors.foreground,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Expanded(
              child: Text(
                app.description ?? '',
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  color: isDark
                      ? AppColors.darkMutedForeground
                      : AppColors.mutedForeground,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Row(
              children: [
                if (app.developerName != null)
                  Expanded(
                    child: Text(
                      app.developerName!,
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        color: isDark
                            ? AppColors.darkMutedForeground
                            : AppColors.mutedForeground,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                Text(
                  'v${app.version ?? '1.0.0'}',
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    color: isDark
                        ? AppColors.darkMutedForeground
                        : AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(ModuleData app, double size, double radius) {
    if (app.iconPath != null && app.iconPath!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.network(
          app.iconPath!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(radius),
            ),
            child: Icon(
              _getIcon(app.icon),
              color: AppColors.primary,
              size: size * 0.52,
            ),
          ),
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(
        _getIcon(app.icon),
        color: AppColors.primary,
        size: size * 0.52,
      ),
    );
  }
}

IconData _getIcon(String? name) {
  switch (name) {
    case 'directions_bus_rounded':
      return Icons.directions_bus_outlined;
    case 'shopping_cart_rounded':
      return Icons.shopping_cart_outlined;
    case 'directions_car_rounded':
      return Icons.directions_car_outlined;
    case 'storefront_rounded':
      return Icons.storefront_outlined;
    case 'account_balance_wallet_rounded':
      return Icons.account_balance_wallet_outlined;
    case 'card_giftcard_rounded':
      return Icons.card_giftcard_outlined;
    case 'play_circle_outline_rounded':
      return Icons.play_circle_outline_outlined;
    case 'work_outline_rounded':
      return Icons.work_outline_outlined;
    default:
      return Icons.widgets_outlined;
  }
}

Widget _buildFeaturedIcon(ModuleData app) {
  if (app.iconPath != null && app.iconPath!.isNotEmpty) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        app.iconPath!,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_getIcon(app.icon), color: Colors.white, size: 22),
        ),
      ),
    );
  }
  return Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.25),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(_getIcon(app.icon), color: Colors.white, size: 22),
  );
}

class _InstalledAppCard extends StatelessWidget {
  final ModuleData app;
  final bool isDark;
  final VoidCallback onTap;

  const _InstalledAppCard({
    required this.app,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 80,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkGlass : AppColors.glass,
          border: Border.all(
            color: isDark ? AppColors.darkGlassBorder : AppColors.glassBorder,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildMiniIcon(40, 10),
            const SizedBox(height: 6),
            Text(
              app.displayName,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkForeground : AppColors.foreground,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniIcon(double size, double radius) {
    if (app.iconPath != null && app.iconPath!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.network(
          app.iconPath!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildDefaultIcon(size, radius),
        ),
      );
    }
    return _buildDefaultIcon(size, radius);
  }

  Widget _buildDefaultIcon(double size, double radius) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(_getIcon(app.icon), color: AppColors.primary, size: size * 0.52),
    );
  }
}
