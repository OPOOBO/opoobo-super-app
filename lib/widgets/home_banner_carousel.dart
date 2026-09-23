import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../utils/navigation.dart';
import '../screens/bus_module_screen.dart';
import '../screens/marketplace_screen.dart';
import '../screens/store_screen.dart';

class HomeBannerItem {
  final String title;
  final String subtitle;
  final String ctaLabel;
  final Color background;
  final VoidCallback? onTap;

  const HomeBannerItem({
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.background,
    this.onTap,
  });
}

/// Compact promo strip. Cards keep the existing Bus, Market, and Store destinations.
class HomeBannerCarousel extends StatelessWidget {
  final bool isDark;

  const HomeBannerCarousel({super.key, required this.isDark});

  List<HomeBannerItem> _banners(BuildContext context) {
    return [
      HomeBannerItem(
        title: 'Book a bus\nticket',
        subtitle: 'Interstate trips',
        ctaLabel: 'Book now',
        background: AppColors.primary,
        onTap: () => NavigationHelper.push(context, const BusModuleScreen()),
      ),
      HomeBannerItem(
        title: 'Market\ndeals',
        subtitle: 'Shop local vendors',
        ctaLabel: 'Shop now',
        background: const Color(0xFF0F5C2E),
        onTap: () => NavigationHelper.push(context, const MarketplaceScreen()),
      ),
      HomeBannerItem(
        title: 'Mini apps\n& tools',
        subtitle: 'Discover the store',
        ctaLabel: 'Explore',
        background: const Color(0xFF1A1A2E),
        onTap: () => NavigationHelper.push(context, const StoreScreen()),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final banners = _banners(context);
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: banners.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = banners[index];
          return SizedBox(
            width: 220,
            child: Material(
              color: item.background,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: item.onTap,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          '${item.ctaLabel} →',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
