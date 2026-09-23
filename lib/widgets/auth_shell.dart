import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart' as gf;
import '../theme/app_colors.dart';
import '../widgets/opoobo_logo.dart';
import '../widgets/opoobo_wordmark.dart';

class AuthShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? footer;

  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [AppColors.darkBackground, AppColors.darkBackground]
                : [AppColors.background, AppColors.background],
          ),
        ),
        child: Stack(
          children: [
            // Mesh background decorations
            Positioned(
              top: -80,
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
            // Content
            SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, topPadding + 24, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo + Wordmark
                  Row(
                    children: [
                      const OpooboLogo(size: 44),
                      const SizedBox(width: 10),
                      OpooboWordmark(isDark: isDark),
                    ],
                  ),
                  const SizedBox(height: 36),
                  // Title
                  Text(
                    title,
                    style: gf.GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.darkForeground
                          : AppColors.foreground,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: gf.GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.darkMutedForeground
                          : AppColors.mutedForeground,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Child content
                  child,
                  if (footer != null) ...[const SizedBox(height: 32), footer!],
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
