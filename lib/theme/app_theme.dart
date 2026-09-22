import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.primaryForeground,
        secondary: AppColors.secondary,
        onSecondary: AppColors.secondaryForeground,
        surface: AppColors.surface,
        onSurface: AppColors.foreground,
        error: AppColors.destructive,
        onError: AppColors.destructiveForeground,
      ),
      dividerColor: AppColors.border,
      splashColor: AppColors.primarySoft,
      highlightColor: AppColors.primarySoft,
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.darkPrimary,
        onPrimary: AppColors.darkPrimaryForeground,
        secondary: AppColors.darkSurface,
        onSecondary: AppColors.darkForeground,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkForeground,
        error: AppColors.destructive,
        onError: AppColors.destructiveForeground,
      ),
      dividerColor: AppColors.darkBorder,
      splashColor: AppColors.darkPrimarySoft,
      highlightColor: AppColors.darkPrimarySoft,
    );
  }
}
