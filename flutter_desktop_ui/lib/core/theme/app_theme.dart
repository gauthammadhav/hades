import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Ergonomic, human-crafted design theme for HADES Desktop.
/// Employs a crisp white canvas with deep spruce green brand elements,
/// subtle micro-shadows, and typographic discipline.
class AppTheme {
  AppTheme._();

  static const double cardRadius = 10.0;
  static const double innerTileRadius = 6.0;
  static const double borderWidth = 1.0;
  static const String monoFont = 'Cascadia Code';
  static const List<String> monoFallbacks = ['Consolas', 'SF Mono', 'Courier New', 'monospace'];

  static List<BoxShadow> get softShadow => const [
    BoxShadow(
      color: Color(0x0A103031), // 4% spruce shadow
      offset: Offset(0, 2),
      blurRadius: 10,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x05103031),
      offset: Offset(0, 1),
      blurRadius: 3,
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get cardHoverShadow => const [
    BoxShadow(
      color: Color(0x12103031),
      offset: Offset(0, 4),
      blurRadius: 14,
      spreadRadius: 0,
    ),
  ];

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Segoe UI',
      fontFamilyFallback: const ['SF Pro Text', 'Inter', '-apple-system', 'Arial', 'sans-serif'],
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.white,
        secondary: AppColors.accent,
        onSecondary: AppColors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.danger,
        onError: AppColors.white,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(cardRadius)),
          side: const BorderSide(color: AppColors.border, width: borderWidth),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        hintStyle: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          backgroundColor: AppColors.surface,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.primaryDark,
          borderRadius: BorderRadius.circular(5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x20000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        textStyle: const TextStyle(
          color: AppColors.white,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(AppColors.border),
        trackColor: WidgetStateProperty.all(AppColors.background),
        thickness: WidgetStateProperty.all(5),
        radius: const Radius.circular(4),
      ),
    );
  }

  // Alias for backward compatibility with existing main.dart call
  static ThemeData get darkTheme => lightTheme;
}
