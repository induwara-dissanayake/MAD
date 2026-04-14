import 'package:flutter/material.dart';

/// Village Connect — "Editorial Ruralism" Color Palette.
///
/// Moving from a generic GovTech look to a premium aesthetic
/// that honors rural users' time and intent. Replaces borders with tonal layering.
class AppColors {
  AppColors._();

  // ── Primary (Nature Green) ────────────────────────────────────────────────
  static const Color primary = Color(0xFF1B5E20); // Premium Nature Green
  static const Color primaryLight = Color(0xFFE8F5E9);
  static const Color primaryDark = Color(0xFF123D15);

  // ── Surfaces (Editorial Ledger) ───────────────────────────────────────────
  static const Color background = Color(0xFFF9F9F9); // Crisp Ledger White
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF3F3F3); // Soft tonal shift
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  
  // ── Legacy / Compatibility Surfaces ──────────────────────────────────────
  static const Color card = Color(0xFFFFFFFF);
  static const Color surfaceGrey = Color(0xFFF3F3F3);
  static const Color secondarySurface = Color(0xFFECECEC);

  // ── Text (Ink & Ash) ─────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF141A14); // Deep Forest Ink
  static const Color textSecondary = Color(0xFF4A4D4A); // Dimmed Ash
  static const Color textMuted = Color(0xFF8E928E);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Semantic Status (Muted Clarity) ──────────────────────────────────────
  static const Color success = Color(0xFF2E7D32);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFF9A825);
  static const Color warningLight = Color(0xFFFFF9C4);
  static const Color error = Color(0xFFD32F2F);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color info = Color(0xFF0277BD);
  static const Color infoLight = Color(0xFFE1F5FE);

  // ── Borders / Dividers (Used sparingly per Stitch "No-Line" rule) ─────────
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFF0F0F0);

  // ── Disabled ────────────────────────────────────────────────────────────
  static const Color disabled = Color(0xFFA5A5A5);
  static const Color disabledBackground = Color(0xFFEEEEEE);

  // ── Shadow (Ambient Elevation) ───────────────────────────────────────────
  static final Color shadow = const Color(0xFF000000).withOpacity(0.04);
  static final Color shadowLight = const Color(0xFF000000).withOpacity(0.02);

  // ── Legacy aliases (keeps existing screen code compiling) ───────────────
  static const Color accentBlue = infoLight;
  static const Color accentGreen = successLight;
  static const Color accentRed = errorLight;
  static const Color accentYellow = warningLight;
  static const Color accentPurple = infoLight;

  // ── Gradient helpers (Nature-inspired) ──────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D631B), Color(0xFF084B14)],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0D631B), Color(0xFF1B5E20)],
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF9F9F9), Color(0xFFFFFFFF)],
  );
}
