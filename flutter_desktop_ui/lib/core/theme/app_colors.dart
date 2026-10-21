import 'package:flutter/material.dart';

/// Central design tokens for the HADES Control Plane.
/// Strictly all colors used in the application must reference this class.
class AppColors {
  AppColors._();

  // Core brand tokens
  static const Color primary = Color(0xFF103031);
  static const Color accent = Color(0xFF083A3B);
  static const Color background = Color(0xFFFFFFFF);
  static const Color canvas = Color(0xFFF8FBFA);
  static const Color surface = Color(0xFFF2F7F6); // mint surface
  static const Color iconSurface = Color(0xFFF1F2F2);
  static const Color textPrimary = Color(0xFF183733);
  static const Color textSecondary = Color(0xFF8A9291);
  static const Color lavender = Color(0xFFE8D5F5);
  static const Color border = Color(0xFFE5ECEA);
  static const Color ok = Color(0xFF2E7D5B);
  static const Color danger = Color(0xFFC0392B);
  static const Color info = Color(0xFF2A7F9E);
  static const Color vmPurple = Color(0xFF7B4FA3);

  // Hero card tokens
  static const Color heroGradientStart = Color(0xFF103031);
  static const Color heroGradientEnd = Color(0xFF0B4547);
  static const Color heroPillBg = Color(0x26FFFFFF); // 15% white
  static const Color heroSubtext = Color(0xB3FFFFFF); // 70% white
  static const Color heroProgressTrack = Color(0x26FFFFFF); // 15% white
  static const Color heroProgressGreen = Color(0xFF5CE0A0);
  static const Color heroProgressRed = Color(0xFFE5534B);
  static const Color heroDecorativeShape = Color(0x08FFFFFF); // 3% white

  // Event stream tokens
  static const Color logDeny = Color(0xFFFF8A80);
  static const Color logAudit = Color(0xFF8FE3B5);
  static const Color logNormal = Color(0xFFB8D5D2);
  static const Color logLiveDot = Color(0xFF4ADE80);

  // Left navigation rail tokens
  static const Color navMuted = Color(0xFF8FB3B0);
  static const Color navActiveTile = Color(0x29FFFFFF); // 16% white
  static const Color logoRing = Color(0xFF234445);

  // Chip backgrounds & accents
  static const Color chipMintBg = Color(0xFFE8F2EE);
  static const Color chipBlueBg = Color(0xFFE3EFF3);
  static const Color chipPurpleBg = Color(0xFFF1EBF7);
  static const Color chipRedBg = Color(0xFFFDECEB);

  // Alert tokens
  static const Color alertRedBg = Color(0xFFFDF2F2);
  static const Color alertRedBorder = Color(0xFFF5C6C3);

  // Disabled and interactive states
  static const Color disabledButtonBg = Color(0xFFB2BEBD);
  static const Color switchTrackInactive = Color(0xFFE5ECEA);
  static const Color switchTrackActive = Color(0xFF2E7D5B);

  // Universal neutral tokens
  static const Color white = Color(0xFFFFFFFF);
  static const Color transparent = Color(0x00000000);
  static const Color shadow = Color(0x0A103031); // primary at ~4% opacity
}
