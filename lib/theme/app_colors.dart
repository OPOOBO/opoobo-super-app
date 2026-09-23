import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary
  static const Color primary = Color(0xFFFF4500);
  static const Color primaryGlow = Color(0xFFBD5A00);
  static const Color primarySoft = Color(0xFFFFF5F2);
  static const Color primaryForeground = Color(0xFFFCFCFC);
  static const Color iconWell = Color(0xFFFFF5F2);

  // Background
  static const Color background = Color(0xFFF5F6FA);
  static const Color foreground = Color(0xFF111827);

  // Surface
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surface2 = Color(0xFFF5F6FA);

  // Secondary
  static const Color secondary = Color(0xFFF3F4F6);
  static const Color secondaryForeground = Color(0xFF374151);

  // Muted
  static const Color muted = Color(0xFFF3F4F6);
  static const Color mutedForeground = Color(0xFF9CA3AF);

  // Accent
  static const Color accent = Color(0xFFFFF5F2);

  // Destructive
  static const Color destructive = Color(0xFFD44333);
  static const Color destructiveForeground = Color(0xFFFCFCFC);

  // Success
  static const Color success = Color(0xFF2D9F6F);
  static const Color successForeground = Color(0xFFFCFCFC);

  // Warning
  static const Color warning = Color(0xFFE5A733);
  static const Color warningForeground = Color(0xFF382E1A);

  // Border
  static const Color border = Color(0xFFF3F4F6);
  static const Color input = Color(0xFFE5E7EB);
  static const Color ring = Color(0xFFFF4500);

  // Cards (solid white; existing glass call sites pick this up)
  static const Color glass = Color(0xFFFFFFFF);
  static const Color glassBorder = Color(0xFFF3F4F6);
  static const Color glassStrong = Color(0xFFFFFFFF);

  // Gradient
  static const LinearGradient gradientPrimary = LinearGradient(
    colors: [primary, primaryGlow],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Dark mode
  static const Color darkBackground = Color(0xFF12141A);
  static const Color darkForeground = Color(0xFFF5F6FA);
  static const Color darkSurface = Color(0xFF1C1F27);
  static const Color darkPrimary = Color(0xFFFF6B35);
  static const Color darkPrimaryForeground = Color(0xFF1C1F27);
  static const Color darkPrimarySoft = Color(0xFF3D2418);
  static const Color darkGlass = Color(0xFF1C1F27);
  static const Color darkGlassBorder = Color(0xFF2A2E38);
  static const Color darkBorder = Color(0xFF2A2E38);
  static const Color darkMutedForeground = Color(0xFF9CA3AF);
}
