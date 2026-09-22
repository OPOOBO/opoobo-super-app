import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../widgets/module_card.dart';
import '../widgets/bottom_nav.dart';
import '../providers/auth_provider.dart';
import '../providers/module_provider.dart';
import '../providers/bus_booking_provider.dart';
import '../providers/dashboard_provider.dart';
import 'search_screen.dart';
import 'services_screen.dart';
import 'activity_screen.dart';
import 'ai_assistant_screen.dart';

import 'profile_screen.dart';
import 'bus_module_screen.dart';
import 'connected_apps_screen.dart';
import 'ticket_detail_screen.dart';
import 'marketplace_screen.dart';
import 'mini_app_screen.dart';
import '../utils/navigation.dart';
import '../widgets/home_banner_carousel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Silent SSO auto-link on first dashboard visit — bus + market
      // accounts are created/linked here so the user never sees it.
      try {
        await context.read<AuthProvider>().ensureModulesLinked();
      } catch (_) {}
      // Refresh link status so Bus + Market show as linked right away.
      try {
        await context.read<ModuleProvider>().loadModules();
      } catch (_) {}
      if (!mounted) return;
      final moduleProvider = context.read<ModuleProvider>();
      final busUid = moduleProvider.getModuleUid('bus');
      if (busUid != null && busUid.isNotEmpty) {
        context.read<BusBookingProvider>().loadBookingHistory(busUid);
      }
      context.read<DashboardProvider>().loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;

    final screens = [
      _HomeContent(
        isDark: isDark,
        topPadding: topPadding,
        onViewActivity: () => setState(() => _currentNavIndex = 2),
      ),
      const ServicesScreen(),
      const ActivityScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentNavIndex, children: screens),
      bottomNavigationBar: BottomNav(
        currentIndex: _currentNavIndex,
        onTap: (index) => setState(() => _currentNavIndex = index),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final bool isDark;
  final double topPadding;
  final VoidCallback? onViewActivity;

  const _HomeContent({
    required this.isDark,
    required this.topPadding,
    this.onViewActivity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: isDark ? AppColors.darkBackground : AppColors.background,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(0, topPadding + 8, 0, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(context),
            const SizedBox(height: 16),
            HomeBannerCarousel(isDark: isDark),
            const SizedBox(height: 16),
            _buildQuickStats(context),
            const SizedBox(height: 20),
            SectionTitle(
              title: 'Your services',
              actionLabel: 'See all',
              onAction: () =>
                  NavigationHelper.push(context, const ConnectedAppsScreen()),
            ),
            const SizedBox(height: 12),
            _buildServicesGrid(context),
            const SizedBox(height: 24),
            SectionTitle(
              title: 'Recent activity',
              actionLabel: 'View all',
              onAction: () => onViewActivity?.call(),
            ),
            const SizedBox(height: 12),
            _buildRecentActivity(context),
            const SizedBox(height: 20),
            _buildConnectedAppsCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => NavigationHelper.push(context, const SearchScreen()),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurface
                      : AppColors.glassStrong,
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkGlassBorder
                        : AppColors.glassBorder,
                  ),
                  borderRadius: BorderRadius.circular(16),
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
                      child: Text(
                        'Search services, trips, orders\u2026',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.darkMutedForeground
                              : AppColors.mutedForeground,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () =>
                NavigationHelper.push(context, const AiAssistantScreen()),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkGlass : AppColors.glass,
                border: Border.all(
                  color: isDark
                      ? AppColors.darkGlassBorder
                      : AppColors.glassBorder,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 22,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    final dashboard = context.watch<DashboardProvider>();
    final busBooking = context.watch<BusBookingProvider>();
    final bookings = busBooking.bookings;
    final spend = dashboard.monthlySpend(bookings);
    final orders = dashboard.activeOrders(bookings);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.card_giftcard_rounded,
              label: 'Reward points',
              value: dashboard.formatPoints(dashboard.rewardPoints),
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              icon: Icons.trending_up_rounded,
              label: 'This month',
              value: dashboard.formatCurrency(spend),
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              icon: Icons.receipt_long_rounded,
              label: 'Active orders',
              value: orders.toString(),
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesGrid(BuildContext context) {
    final modules = context.watch<ModuleProvider>().modules;
    if (modules.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 0.85,
        children: modules
            .map((m) => _ModuleCard(module: m, isDark: isDark))
            .toList(),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    final busBooking = context.watch<BusBookingProvider>();
    final bookings = busBooking.bookings;
    final recent = bookings.take(3).toList();

    if (recent.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkGlass : AppColors.glass,
            border: Border.all(
              color: isDark ? AppColors.darkGlassBorder : AppColors.glassBorder,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(
            child: Text(
              'No recent activity',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.darkMutedForeground
                    : AppColors.mutedForeground,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkGlass : AppColors.glass,
          border: Border.all(
            color: isDark ? AppColors.darkGlassBorder : AppColors.glassBorder,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: List.generate(recent.length, (index) {
            final b = recent[index];
            final isLast = index == recent.length - 1;
            final Color statusColor;
            if (b.isConfirmed) {
              statusColor = const Color(0xFF2D9F6F);
            } else if (b.isCancelled) {
              statusColor = AppColors.destructive;
            } else {
              statusColor = const Color(0xFFE5A733);
            }

            return GestureDetector(
              onTap: () {
                final busUid =
                    context.read<ModuleProvider>().getModuleUid('bus') ?? '';
                context
                    .read<BusBookingProvider>()
                    .loadBookingDetails(busUid, b.ticketId)
                    .then((_) {
                      if (context.mounted) {
                        NavigationHelper.push(
                          context,
                          const TicketDetailScreen(),
                        );
                      }
                    });
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: isLast
                    ? null
                    : BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.border,
                            width: 0.5,
                          ),
                        ),
                      ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.directions_bus_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${b.boardingCity} → ${b.dropCity}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.darkForeground
                                  : AppColors.foreground,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${b.busName} · ${b.passengerNames}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.darkMutedForeground
                                  : AppColors.mutedForeground,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\u20a6${b.ticketPrice}',
                          style: GoogleFonts.sora(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkForeground
                                : AppColors.foreground,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            b.bookingStatus,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildConnectedAppsCard(BuildContext context) {
    final modules = context.watch<ModuleProvider>().modules;
    final linkedCount = modules.where((m) => m.isLinked).length;

    return GestureDetector(
      onTap: () => NavigationHelper.push(context, const ConnectedAppsScreen()),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkGlass : AppColors.glass,
          border: Border.all(
            color: isDark ? AppColors.darkGlassBorder : AppColors.glassBorder,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                gradient: AppColors.gradientPrimary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.grid_view_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Connected apps',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkForeground
                          : AppColors.foreground,
                    ),
                  ),
                  Text(
                    '$linkedCount linked \u00b7 ${modules.length - linkedCount} coming soon',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.darkMutedForeground
                          : AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: isDark
                  ? AppColors.darkMutedForeground
                  : AppColors.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkGlass : AppColors.glass,
        border: Border.all(
          color: isDark ? AppColors.darkGlassBorder : AppColors.glassBorder,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.sora(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkForeground : AppColors.foreground,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.darkMutedForeground
                  : AppColors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final ModuleData module;
  final bool isDark;

  const _ModuleCard({required this.module, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isLinked = module.isLinked;
    final isComingSoon = !module.isActive;

    return GestureDetector(
      onTap: () {
        if (module.isMiniApp) {
          NavigationHelper.push(context, MiniAppScreen(module: module));
          return;
        }
        if (module.name == 'bus') {
          NavigationHelper.push(context, const BusModuleScreen());
        } else if (module.name == 'market') {
          if (!isComingSoon) {
            NavigationHelper.push(context, const MarketplaceScreen());
            return;
          }
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
                  child: _buildIcon(module, 48, 16),
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
                      'Coming soon',
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

  Widget _buildIcon(ModuleData module, double size, double radius) {
    if (module.iconPath != null && module.iconPath!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.network(
          module.iconPath!,
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
              _getIcon(module.icon),
              color: AppColors.primary,
              size: size * 0.5,
            ),
          ),
        ),
      );
    }
    return Icon(
      _getIcon(module.icon),
      color: AppColors.primary,
      size: 24,
    );
  }

  IconData _getIcon(String? name) {
    switch (name) {
      case 'directions_bus_rounded':
        return Icons.directions_bus_rounded;
      case 'shopping_cart_rounded':
        return Icons.shopping_cart_rounded;
      case 'directions_car_rounded':
        return Icons.directions_car_rounded;
      case 'storefront_rounded':
        return Icons.storefront_rounded;
      case 'account_balance_wallet_rounded':
        return Icons.account_balance_wallet_rounded;
      case 'card_giftcard_rounded':
        return Icons.card_giftcard_rounded;
      case 'play_circle_outline_rounded':
        return Icons.play_circle_outline_rounded;
      case 'work_outline_rounded':
        return Icons.work_outline_rounded;
      default:
        return Icons.widgets_rounded;
    }
  }
}
