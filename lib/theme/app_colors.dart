import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary
  static const Color primary = Color(0xFFFF4500);
  static const Color primaryGlow = Color(0xFFBD5A00);
  static const Color primarySoft = Color(0xFFF0D4C0);
  static const Color primaryForeground = Color(0xFFFCFCFC);

  // Background
  static const Color background = Color(0xFFFAF9F6);
  static const Color foreground = Color(0xFF2C2620);

  // Surface
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surface2 = Color(0xFFF6F5F2);

  // Secondary
  static const Color secondary = Color(0xFFF2F1EE);
  static const Color secondaryForeground = Color(0xFF3D362E);

  // Muted
  static const Color muted = Color(0xFFF2F1EE);
  static const Color mutedForeground = Color(0xFF878078);

  // Accent
  static const Color accent = Color(0xFFF2EDE8);

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
  static const Color border = Color(0xFFE8E6E1);
  static const Color input = Color(0xFFE8E6E1);
  static const Color ring = Color(0xFFFF4500);

  // Glass
  static const Color glass = Color(0x9EFFFFFF);
  static const Color glassBorder = Color(0xB3FFFFFF);
  static const Color glassStrong = Color(0xC7FFFFFF);

  // Gradient
  static const LinearGradient gradientPrimary = LinearGradient(
    colors: [primary, primaryGlow],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Dark mode
  static const Color darkBackground = Color(0xFF28231E);
  static const Color darkForeground = Color(0xFFF7F6F3);
  static const Color darkSurface = Color(0xFF36302A);
  static const Color darkPrimary = Color(0xFFFF6B35);
  static const Color darkPrimaryForeground = Color(0xFF26211C);
  static const Color darkPrimarySoft = Color(0xFF4D3320);
  static const Color darkGlass = Color(0x12FFFFFF);
  static const Color darkGlassBorder = Color(0x1FFFFFFF);
  static const Color darkBorder = Color(0x1AFFFFFF);
  static const Color darkMutedForeground = Color(0xFFB0A99E);
}
