import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/home_banner_carousel.dart';
import '../widgets/line_icon.dart';
import '../providers/auth_provider.dart';
import '../providers/module_provider.dart';
import '../providers/bus_booking_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/offer_provider.dart';
import '../widgets/offer_cards.dart';
import 'search_screen.dart';
import 'services_screen.dart';
import 'ai_assistant_screen.dart';
import 'profile_screen.dart';
import 'bus_module_screen.dart';
import 'marketplace_screen.dart';
import 'mini_app_screen.dart';
import 'rewards_screen.dart';
import 'deals_screen.dart';
import 'scan_screen.dart';
import '../utils/navigation.dart';

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
      try {
        await context.read<AuthProvider>().ensureModulesLinked();
      } catch (_) {}
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
      context.read<OfferProvider>().load();
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
        onSeeAllServices: () => setState(() => _currentNavIndex = 2),
      ),
      ScanScreen(active: _currentNavIndex == 1),
      const ServicesScreen(),
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
  final VoidCallback onSeeAllServices;

  const _HomeContent({
    required this.isDark,
    required this.topPadding,
    required this.onSeeAllServices,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: isDark ? AppColors.darkBackground : AppColors.background,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(0, topPadding + 12, 0, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(context),
            const SizedBox(height: 16),
            HomeBannerCarousel(isDark: isDark),
            const SizedBox(height: 20),
            _SectionTitle(
              title: 'Services',
              actionLabel: 'See all',
              isDark: isDark,
              onAction: onSeeAllServices,
            ),
            const SizedBox(height: 12),
            _buildServicesGrid(context),
            const SizedBox(height: 20),
            _buildPromo(context),
            const SizedBox(height: 20),
            _SectionTitle(
              title: 'Daily Deals',
              actionLabel: 'View all',
              isDark: isDark,
              onAction: () =>
                  NavigationHelper.push(context, const DealsScreen()),
            ),
            const SizedBox(height: 12),
            _buildDeals(context),
            const SizedBox(height: 20),
            _SectionTitle(
              title: 'My Rewards',
              actionLabel: 'Details',
              isDark: isDark,
              onAction: () =>
                  NavigationHelper.push(context, const RewardsScreen()),
            ),
            const SizedBox(height: 12),
            _buildRewards(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => NavigationHelper.push(context, const SearchScreen()),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.surface,
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    LineIcon(
                      name: 'search',
                      size: 20,
                      color: isDark
                          ? AppColors.darkMutedForeground
                          : AppColors.mutedForeground,
                      strokeWidth: 2,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Search services, trips, orders...',
                        style: GoogleFonts.inter(
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
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () =>
                NavigationHelper.push(context, const AiAssistantScreen()),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.surface,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome, size: 18, color: AppColors.primary),
                  Text(
                    'AI',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesGrid(BuildContext context) {
    final modules = context.watch<ModuleProvider>().modules.take(8).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
        child: modules.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Services will show up here',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkMutedForeground
                        : AppColors.mutedForeground,
                  ),
                ),
              )
            : GridView.count(
                crossAxisCount: 4,
                mainAxisSpacing: 16,
                crossAxisSpacing: 8,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 0.78,
                children: modules
                    .map((m) => _ServiceTile(module: m, isDark: isDark))
                    .toList(),
              ),
      ),
    );
  }

  Widget _buildPromo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFACC15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'EXCLUSIVE',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF713F12),
                  letterSpacing: 0.4,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Get 1000 Bonus\nReward Points',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                height: 1.15,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Complete any 3 services this week',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () =>
                  NavigationHelper.push(context, const RewardsScreen()),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Claim Now →',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeals(BuildContext context) {
    final offers = context.watch<OfferProvider>();
    if (offers.loadingDeals && offers.deals.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: LinearProgressIndicator(minHeight: 2, color: AppColors.primary),
      );
    }
    if (offers.deals.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          offers.dealsError ?? 'No deals right now',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: isDark
                ? AppColors.darkMutedForeground
                : AppColors.mutedForeground,
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (final deal in offers.deals) ...[
            DealRow(deal: deal, isDark: isDark),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _buildRewards(BuildContext context) {
    final offers = context.watch<OfferProvider>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: RewardsSummaryCard(
        summary: offers.rewards,
        loading: offers.loadingRewards && offers.rewards == null,
        message: offers.rewardsError,
        isDark: isDark,
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final ModuleData module;
  final bool isDark;

  const _ServiceTile({required this.module, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openModule(context, module),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkPrimarySoft : AppColors.iconWell,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: ModuleLineIcon(
                moduleName: module.name,
                size: 28,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            module.displayName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              height: 1.15,
              color: isDark ? AppColors.darkForeground : const Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    );
  }
}

void _openModule(BuildContext context, ModuleData module) {
  if (module.isMiniApp) {
    NavigationHelper.push(context, MiniAppScreen(module: module));
    return;
  }
  if (module.name == 'bus') {
    NavigationHelper.push(context, const BusModuleScreen());
    return;
  }
  if (module.name == 'market' && module.isActive) {
    NavigationHelper.push(context, const MarketplaceScreen());
    return;
  }
  final url = module.websiteUrl ?? 'https://opoobo.com';
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

class _SectionTitle extends StatelessWidget {
  final String title;
  final String actionLabel;
  final bool isDark;
  final VoidCallback onAction;

  const _SectionTitle({
    required this.title,
    required this.actionLabel,
    required this.isDark,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkForeground : AppColors.foreground,
              ),
            ),
          ),
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
