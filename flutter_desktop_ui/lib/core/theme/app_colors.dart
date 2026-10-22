import 'package:flutter/material.dart';

/// Central design tokens for the HADES Control Plane & Hardware Dashboard.
/// Professional white & dark spruce green theme with high typographic clarity.
class AppColors {
  AppColors._();

  // ── Core Brand (Dark Spruce Green) ─────────────────────────────────────────
  static const Color primary = Color(0xFF103031);
  static const Color primaryDark = Color(0xFF092021);
  static const Color primaryLight = Color(0xFF1A4749);

  /// Spruce teal interactive accent
  static const Color accent = Color(0xFF1B6B63);
  static const Color accentDim = Color(0xFF103031);
  static const Color accentBg = Color(0xFFE8F2EE); // Mint tint for badges / selection

  // ── Light Theme Surfaces ───────────────────────────────────────────────────
  /// Main window/scaffold canvas background
  static const Color background = Color(0xFFF7FAF9);
  static const Color canvas = Color(0xFFF8FBFA);

  /// Card and container surfaces
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSubtle = Color(0xFFF2F7F5);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color iconSurface = Color(0xFFF1F6F4);

  /// Grid & component borders
  static const Color border = Color(0xFFE2EBE8);
  static const Color borderSubtle = Color(0xFFEDF3F1);
  static const Color divider = Color(0xFFEAEFEB);
  static const Color shadow = Color(0x0A103031); // 4% primary shadow

  // ── Typography ─────────────────────────────────────────────────────────────
  /// Deep dark spruce slate — soft on the eyes, avoids harsh #000
  static const Color textPrimary = Color(0xFF132A27);
  /// Muted slate secondary text
  static const Color textSecondary = Color(0xFF5E7572);
  /// Placeholder and disabled text
  static const Color textMuted = Color(0xFF8FA3A0);
  /// Monospace code token color
  static const Color mono = Color(0xFF103031);

  // ── Semantic Status Colors ─────────────────────────────────────────────────
  static const Color ok = Color(0xFF2E7D5B); // Forest emerald
  static const Color danger = Color(0xFFC0392B); // Crimson
  static const Color info = Color(0xFF2A7F9E); // Marine teal
  static const Color warning = Color(0xFFD97706); // Amber

  static const Color statusOnline = ok;
  static const Color statusOffline = danger;
  static const Color statusWarning = warning;
  static const Color statusConnecting = info;
  static const Color statusMuted = textMuted;

  // ── Hardware Two-Stage Resolution ──────────────────────────────────────────
  static const Color resolved = Color(0xFF2E7D5B);
  static const Color resolvedBg = Color(0xFFE8F2EE);

  static const Color manifest = Color(0xFF2A7F9E);
  static const Color manifestBg = Color(0xFFE3EFF3);

  static const Color ambiguous = Color(0xFFD97706);
  static const Color ambiguousBg = Color(0xFFFEF3C7);

  // ── Event Feed Colors ──────────────────────────────────────────────────────
  static const Color eventAdd = Color(0xFF2E7D5B);
  static const Color eventRemove = Color(0xFFC0392B);
  static const Color eventReEnum = Color(0xFF2A7F9E);
  static const Color eventInfo = Color(0xFF5E7572);

  // ── Navigation Rail (Spruce Dark) ──────────────────────────────────────────
  static const Color navRailBg = Color(0xFF103031);
  static const Color navMuted = Color(0xFF8FB3B0);
  static const Color navActiveTile = Color(0x29FFFFFF); // 16% white
  static const Color logoRing = Color(0xFF234445);

  // ── Chip Badges ────────────────────────────────────────────────────────────
  static const Color chipMintBg = Color(0xFFE8F2EE);
  static const Color chipBlueBg = Color(0xFFE3EFF3);
  static const Color chipPurpleBg = Color(0xFFF1EBF7);
  static const Color chipRedBg = Color(0xFFFDECEB);
  static const Color chipAmberBg = Color(0xFFFEF3C7);

  // ── Universal Neutrals ─────────────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color transparent = Color(0x00000000);
  static const Color vmPurple = Color(0xFF7B4FA3);
  static const Color lavender = Color(0xFFE8D5F5);

  // ── Compatibility Aliases (for controllers & existing views) ───────────────
  static const Color bg0 = navRailBg;
  static const Color bg1 = surface;
  static const Color bg2 = surfaceSubtle;
  static const Color bg3 = accentBg;

  static const Color alertRedBg = Color(0xFFFDF2F2);
  static const Color alertRedBorder = Color(0xFFF5C6C3);
  static const Color disabledButtonBg = Color(0xFFB2BEBD);
  static const Color switchTrackInactive = Color(0xFFE5ECEA);
  static const Color switchTrackActive = Color(0xFF2E7D5B);
  static const Color logDeny = Color(0xFFFF8A80);
  static const Color logAudit = Color(0xFF8FE3B5);
  static const Color logNormal = Color(0xFFB8D5D2);
  static const Color logLiveDot = Color(0xFF4ADE80);
  static const Color heroProgressRed = Color(0xFFE5534B);
  static const Color heroProgressTrack = Color(0x26FFFFFF);
  static const Color heroProgressGreen = Color(0xFF5CE0A0);
  static const Color heroDecorativeShape = Color(0x08FFFFFF);
  static const Color heroPillBg = Color(0x26FFFFFF);
  static const Color heroSubtext = Color(0xB3FFFFFF);
  static const Color heroGradientStart = Color(0xFF103031);
  static const Color heroGradientEnd = Color(0xFF0B4547);
}
