import 'package:flutter/material.dart';

/// Village Connect — Professional color palette.
///
/// Replaces the flat-pastel "AI-generated" palette with a layered surface
/// system and semantic accent colours that feel deliberate and trustworthy.
class AppColors {
  AppColors._();

  // ── Primary ─────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF1565C0); // Warmer government blue
  static const Color primaryLight = Color(0xFFE3F2FD);
  static const Color primaryDark = Color(0xFF0D47A1);

  // ── Surfaces ────────────────────────────────────────────────────────────
  static const Color background = Color(0xFFF5F7FA); // Warm off-white
  static const Color card = Color(0xFFFFFFFF);
  static const Color surfaceGrey = Color(0xFFF0F2F5);
  static const Color secondarySurface = Color(0xFFEBEFF5);

  // ── Text ────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1A1D21);
  static const Color textSecondary = Color(0xFF5F6368);
  static const Color textMuted = Color(0xFF9AA0A6);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Semantic Status ─────────────────────────────────────────────────────
  static const Color success = Color(0xFF2E7D32);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFF57F17);
  static const Color warningLight = Color(0xFFFFF8E1);
  static const Color error = Color(0xFFC62828);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color info = Color(0xFF00838F);
  static const Color infoLight = Color(0xFFE0F7FA);

  // ── Borders / Dividers ──────────────────────────────────────────────────
  static const Color border = Color(0xFFE0E3E8);
  static const Color divider = Color(0xFFECEFF1);

  // ── Disabled ────────────────────────────────────────────────────────────
  static const Color disabled = Color(0xFFBDBDBD);
  static const Color disabledBackground = Color(0xFFE8EAED);

  // ── Shadow ──────────────────────────────────────────────────────────────
  static final Color shadow = const Color(0xFF1A1D21).withOpacity(0.08);
  static final Color shadowLight = const Color(0xFF1A1D21).withOpacity(0.04);

  // ── Legacy aliases (keeps existing screen code compiling) ───────────────
  /// @deprecated – use [primaryLight] instead
  static const Color accentBlue = primaryLight;

  /// @deprecated – use [successLight] instead
  static const Color accentGreen = successLight;

  /// @deprecated – use [errorLight] instead
  static const Color accentRed = errorLight;

  /// @deprecated – use [warningLight] instead
  static const Color accentYellow = warningLight;

  /// @deprecated – use [infoLight] instead
  static const Color accentPurple = infoLight;

  // ── Gradient helpers ────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1976D2), Color(0xFF0D47A1)],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF5F7FA), Color(0xFFFFFFFF)],
  );
}
