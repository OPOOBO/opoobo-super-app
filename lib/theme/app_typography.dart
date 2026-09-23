import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static TextStyle display({bool isDark = false}) => GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: isDark ? AppColors.darkForeground : AppColors.foreground,
    height: 1.2,
  );

  static TextStyle h1({bool isDark = false}) => GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: isDark ? AppColors.darkForeground : AppColors.foreground,
    height: 1.25,
  );

  static TextStyle h2({bool isDark = false}) => GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: isDark ? AppColors.darkForeground : AppColors.foreground,
    height: 1.3,
  );

  static TextStyle h3({bool isDark = false}) => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: isDark ? AppColors.darkForeground : AppColors.foreground,
    height: 1.35,
  );

  static TextStyle h4({bool isDark = false}) => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: isDark ? AppColors.darkForeground : AppColors.foreground,
    height: 1.4,
  );

  static TextStyle body({bool isDark = false}) => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: isDark ? AppColors.darkForeground : AppColors.foreground,
    height: 1.5,
  );

  static TextStyle bodySmall({bool isDark = false}) => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground,
    height: 1.4,
  );

  static TextStyle label({bool isDark = false}) => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground,
    height: 1.3,
    letterSpacing: 0.5,
  );

  static TextStyle caption({bool isDark = false}) => GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground,
    height: 1.3,
    letterSpacing: 0.3,
  );

  static TextStyle button() => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryForeground,
    height: 1.2,
  );

  static TextStyle walletBalance({bool isDark = false}) => GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    height: 1.1,
  );
}
