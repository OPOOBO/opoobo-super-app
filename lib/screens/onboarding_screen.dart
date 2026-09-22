import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../widgets/opoobo_logo.dart';
import '../screens/auth/login_screen.dart';
import '../utils/navigation.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      NavigationHelper.pushReplacement(context, const LoginScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: isDark ? AppColors.darkBackground : AppColors.background,
        child: Stack(
          children: [
            // Mesh background
            Positioned(
              top: -100,
              left: -60,
              child: _MeshBlob(
                color: AppColors.primary.withValues(alpha: 0.15),
                size: 280,
              ),
            ),
            Positioned(
              top: -40,
              right: -80,
              child: _MeshBlob(
                color: AppColors.primaryGlow.withValues(alpha: 0.12),
                size: 240,
              ),
            ),
            // Top bar
            Positioned(
              top: topPadding + 8,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const OpooboLogo(size: 36),
                  GestureDetector(
                    onTap: () => NavigationHelper.pushReplacement(
                      context,
                      const LoginScreen(),
                    ),
                    child: Text(
                      'Skip',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkMutedForeground
                            : AppColors.mutedForeground,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Page content
            PageView.builder(
              controller: _pageController,
              itemCount: 4,
              onPageChanged: (index) => setState(() => _currentStep = index),
              itemBuilder: (context, index) =>
                  _OnboardingStep(step: index, isDark: isDark),
            ),
            // Bottom section
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 24,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  // Step indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      final isActive = index == _currentStep;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: isActive ? 28 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          gradient: isActive ? AppColors.gradientPrimary : null,
                          color: isActive
                              ? null
                              : (isDark
                                    ? AppColors.darkBorder
                                    : AppColors.border),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  // Next button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: null,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: EdgeInsets.zero,
                        elevation: 0,
                      ),
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          gradient: AppColors.gradientPrimary,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.45),
                              blurRadius: 34,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _currentStep == 3 ? 'Get Started' : 'Next',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
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
    );
  }
}

class _MeshBlob extends StatelessWidget {
  final Color color;
  final double size;

  const _MeshBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}

class _OnboardingStep extends StatelessWidget {
  final int step;
  final bool isDark;

  const _OnboardingStep({required this.step, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 80,
        20,
        180,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkGlass : AppColors.glass,
          border: Border.all(
            color: isDark ? AppColors.darkGlassBorder : AppColors.glassBorder,
          ),
          borderRadius: BorderRadius.circular(32),
        ),
        clipBehavior: Clip.antiAlias,
        child: _buildArt(isDark),
      ),
    );
  }

  Widget _buildArt(bool isDark) {
    switch (step) {
      case 0:
        return _MergeArt(isDark: isDark);
      case 1:
        return _IdentityArt(isDark: isDark);
      case 2:
        return _GridArt(isDark: isDark);
      case 3:
        return _HandoffArt(isDark: isDark);
      default:
        return const SizedBox();
    }
  }
}

class _MergeArt extends StatelessWidget {
  final bool isDark;
  const _MergeArt({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 2x2 grid of icons
        Positioned(
          top: 40,
          left: 30,
          child: _GlassTile(icon: Icons.directions_bus_rounded, isDark: isDark),
        ),
        Positioned(
          top: 40,
          right: 30,
          child: _GlassTile(icon: Icons.restaurant_rounded, isDark: isDark),
        ),
        Positioned(
          bottom: 60,
          left: 30,
          child: _GlassTile(
            icon: Icons.shopping_basket_rounded,
            isDark: isDark,
          ),
        ),
        Positioned(
          bottom: 60,
          right: 30,
          child: _GlassTile(icon: Icons.directions_car_rounded, isDark: isDark),
        ),
        // Arrow dashed line
        Positioned(
          top: 0,
          bottom: 0,
          left: 0,
          right: 0,
          child: Center(
            child: CustomPaint(
              size: const Size(80, 80),
              painter: _DashedArrowPainter(),
            ),
          ),
        ),
        // Floating logo
        Positioned(bottom: 20, right: 20, child: const OpooboLogo(size: 72)),
      ],
    );
  }
}

class _IdentityArt extends StatelessWidget {
  final bool isDark;
  const _IdentityArt({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Fingerprint
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: AppColors.gradientPrimary,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.45),
                  blurRadius: 34,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.fingerprint_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
        ),
        // Row of tiles
        Positioned(
          bottom: 50,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _GlassTile(
                icon: Icons.account_balance_wallet_rounded,
                size: 44,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _GlassTile(
                icon: Icons.directions_bus_rounded,
                size: 44,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _GlassTile(icon: Icons.flight_rounded, size: 44, isDark: isDark),
              const SizedBox(width: 8),
              _GlassTile(
                icon: Icons.shopping_basket_rounded,
                size: 44,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _GlassTile(
                icon: Icons.directions_car_rounded,
                size: 44,
                isDark: isDark,
              ),
            ],
          ),
        ),
        // Label
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.secondary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'One identity \u00b7 15 services',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkMutedForeground
                      : AppColors.mutedForeground,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GridArt extends StatelessWidget {
  final bool isDark;
  const _GridArt({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final icons = [
      Icons.directions_bus_rounded,
      Icons.restaurant_rounded,
      Icons.shopping_basket_rounded,
      Icons.account_balance_wallet_rounded,
      Icons.directions_car_rounded,
      Icons.layers_rounded,
      Icons.flight_rounded,
      Icons.smartphone_rounded,
      Icons.favorite_rounded,
    ];

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: GridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: List.generate(9, (index) {
            final isPrimary = index == 4;
            return Container(
              decoration: BoxDecoration(
                gradient: isPrimary ? AppColors.gradientPrimary : null,
                color: isPrimary
                    ? null
                    : (isDark ? AppColors.darkSurface : AppColors.secondary),
                borderRadius: BorderRadius.circular(16),
                boxShadow: isPrimary
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.45),
                          blurRadius: 34,
                          offset: const Offset(0, 10),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                icons[index],
                color: isPrimary ? Colors.white : AppColors.primary,
                size: 28,
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _HandoffArt extends StatelessWidget {
  final bool isDark;
  const _HandoffArt({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Mini phone mockup
        Positioned(
          top: 50,
          left: 40,
          child: Container(
            width: 80,
            height: 128,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.glassStrong,
              border: Border.all(
                color: isDark
                    ? AppColors.darkGlassBorder
                    : AppColors.glassBorder,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Center(
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkBackground
                      : AppColors.secondary,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
        // Arrow
        Positioned(
          top: 90,
          left: 130,
          child: Icon(
            Icons.arrow_forward_rounded,
            color: AppColors.primary,
            size: 28,
          ),
        ),
        // Floating phone card
        Positioned(
          top: 35,
          right: 30,
          child: Container(
            width: 96,
            height: 144,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.glassStrong,
              border: Border.all(
                color: isDark
                    ? AppColors.darkGlassBorder
                    : AppColors.glassBorder,
              ),
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.directions_bus_rounded,
                  color: AppColors.primary,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'Bus app',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkMutedForeground
                        : AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GlassTile extends StatelessWidget {
  final IconData icon;
  final double size;
  final bool isDark;

  const _GlassTile({required this.icon, this.size = 40, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkGlass : AppColors.glass,
        border: Border.all(
          color: isDark ? AppColors.darkGlassBorder : AppColors.glassBorder,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: AppColors.primary, size: size * 0.5),
    );
  }
}

class _DashedArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path()
      ..moveTo(0, size.height / 2)
      ..lineTo(size.width, size.height / 2);

    canvas.drawPath(path, paint);

    // Arrowhead
    final arrowPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    final arrowPath = Path()
      ..moveTo(size.width - 12, size.height / 2 - 6)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(size.width - 12, size.height / 2 + 6)
      ..close();

    canvas.drawPath(arrowPath, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
