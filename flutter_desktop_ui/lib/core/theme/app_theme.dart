import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static const double cardRadius = 22.0;
  static const double innerTileRadius = 16.0;
  static const double borderWidth = 1.5;

  static List<BoxShadow> get softShadow => const [
    BoxShadow(
      color: AppColors.shadow,
      offset: Offset(0, 3),
      blurRadius: 10,
      spreadRadius: 0,
    ),
  ];

  static ThemeData get lightTheme {
    const fallbackFonts = [
      'Inter',
      'Segoe UI',
      'San Francisco',
      'Helvetica Neue',
      'Arial',
      'sans-serif',
    ];

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.primary,
      fontFamily: 'Inter',
      fontFamilyFallback: fallbackFonts,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.white,
        secondary: AppColors.accent,
        onSecondary: AppColors.white,
        surface: AppColors.canvas,
        onSurface: AppColors.textPrimary,
        error: AppColors.danger,
        onError: AppColors.white,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.background,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(cardRadius)),
          side: BorderSide(color: AppColors.border, width: borderWidth),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 0,
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFamilyFallback: fallbackFonts,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border, width: borderWidth),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFamilyFallback: fallbackFonts,
          ),
        ),
      ),
    );
  }
}
