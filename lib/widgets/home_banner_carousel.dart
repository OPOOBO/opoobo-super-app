import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../utils/navigation.dart';
import '../screens/bus_module_screen.dart';
import '../screens/marketplace_screen.dart';
import '../screens/store_screen.dart';

const double _kBannerCardRadius = 24;

/// Promo banner model for the homescreen carousel.
class HomeBannerItem {
  final String brand;
  final String title;
  final String ctaLabel;
  final IconData brandIcon;
  final IconData artIcon;
  final Color background;
  final Color accent;
  final VoidCallback? onTap;

  const HomeBannerItem({
    required this.brand,
    required this.title,
    required this.ctaLabel,
    required this.brandIcon,
    required this.artIcon,
    required this.background,
    required this.accent,
    this.onTap,
  });
}

/// Horizontal banner carousel (Kaspi-style structure) for the homescreen.
/// Soft-colored cards with brand row, title, CTA, and right-side art;
/// next card peeks at the edge.
class HomeBannerCarousel extends StatefulWidget {
  final bool isDark;

  const HomeBannerCarousel({super.key, required this.isDark});

  @override
  State<HomeBannerCarousel> createState() => _HomeBannerCarouselState();
}

class _HomeBannerCarouselState extends State<HomeBannerCarousel> {
  late final PageController _controller;
  int _index = 0;

  static const double _viewportFraction = 0.88;
  static const double _cardHeight = 168;
  static const double _gap = 12;

  List<HomeBannerItem> _banners(BuildContext context) {
    return [
      HomeBannerItem(
        brand: 'OPOOBO Bus',
        title: 'Book interstate\nbus tickets',
        ctaLabel: 'Book now',
        brandIcon: Icons.directions_bus_rounded,
        artIcon: Icons.directions_bus_filled_rounded,
        background: const Color(0xFFFFE8DE),
        accent: AppColors.primary,
        onTap: () =>
            NavigationHelper.push(context, const BusModuleScreen()),
      ),
      HomeBannerItem(
        brand: 'OPOOBO Market',
        title: 'Shop groceries\n& local deals',
        ctaLabel: 'Shop now',
        brandIcon: Icons.shopping_basket_rounded,
        artIcon: Icons.storefront_rounded,
        background: const Color(0xFFE5F5EC),
        accent: const Color(0xFF2D9F6F),
        onTap: () =>
            NavigationHelper.push(context, const MarketplaceScreen()),
      ),
      HomeBannerItem(
        brand: 'OPOOBO Store',
        title: 'Discover mini\napps & tools',
        ctaLabel: 'Explore',
        brandIcon: Icons.apps_rounded,
        artIcon: Icons.grid_view_rounded,
        background: const Color(0xFFE8EEF8),
        accent: const Color(0xFF4A7FD4),
        onTap: () => NavigationHelper.push(context, const StoreScreen()),
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: _viewportFraction);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banners = _banners(context);

    return Column(
      children: [
        SizedBox(
          height: _cardHeight,
          child: PageView.builder(
            controller: _controller,
            itemCount: banners.length,
            padEnds: true,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, index) {
              final item = banners[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: _gap / 2),
                child: _BannerCard(item: item, isDark: widget.isDark),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(banners.length, (i) {
            final active = i == _index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active
                    ? AppColors.primary
                    : (widget.isDark
                        ? AppColors.darkMutedForeground.withValues(alpha: 0.35)
                        : AppColors.mutedForeground.withValues(alpha: 0.35)),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  final HomeBannerItem item;
  final bool isDark;

  const _BannerCard({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark
        ? Color.lerp(item.background, AppColors.darkSurface, 0.55)!
        : item.background;
    final titleColor =
        isDark ? AppColors.darkForeground : AppColors.foreground;
    final brandColor =
        isDark ? AppColors.darkForeground : AppColors.foreground;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(_kBannerCardRadius),
        child: Ink(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(_kBannerCardRadius),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_kBannerCardRadius),
            child: Stack(
              children: [
                Positioned(
                  right: -18,
                  bottom: -24,
                  child: Icon(
                    item.artIcon,
                    size: 140,
                    color: item.accent.withValues(alpha: isDark ? 0.22 : 0.18),
                  ),
                ),
                Positioned(
                  right: 18,
                  top: 22,
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: item.accent.withValues(alpha: isDark ? 0.2 : 0.14),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Icon(
                      item.artIcon,
                      size: 44,
                      color: item.accent.withValues(alpha: 0.9),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 110, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(item.brandIcon, size: 16, color: item.accent),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              item.brand,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: brandColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.sora(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                            color: titleColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: item.onTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: item.accent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            item.ctaLabel,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
