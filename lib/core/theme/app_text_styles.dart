import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Village Connect — "Editorial Ruralism" Typography System.
///
/// Dual-font system:
/// 1. **Public Sans** (Headlines/Display): Authoritative, geometric, and trustworthy.
/// 2. **Inter** (Body/Labels): High legibility and modern clarity.
///
/// Features intentional letter-spacing for headlines and high line-height for body.
class AppTextStyles {
  AppTextStyles._();

  static String? get _displayFont => GoogleFonts.publicSans().fontFamily;
  static String? get _bodyFont => GoogleFonts.inter().fontFamily;

  static const List<String> _fontFallback = [
    'NotoSansSinhala',
    'NotoSansTamil',
  ];

  // ── Display ─────────────────────────────────────────────────────────────
  static TextStyle displayLarge = TextStyle(
    fontFamily: _displayFont,
    fontFamilyFallback: _fontFallback,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 2.2, // Aggressive increase to fix overlapping
    leadingDistribution: TextLeadingDistribution.even,
    letterSpacing: 0,
  );

  static TextStyle displaySmall = TextStyle(
    fontFamily: _displayFont,
    fontFamilyFallback: _fontFallback,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 2.1,
    leadingDistribution: TextLeadingDistribution.even,
    letterSpacing: 0,
  );

  // ── Headings ────────────────────────────────────────────────────────────
  static TextStyle h1 = TextStyle(
    fontFamily: _displayFont,
    fontFamilyFallback: _fontFallback,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 2.0,
    leadingDistribution: TextLeadingDistribution.even,
    letterSpacing: 0,
  );

  static TextStyle h2 = TextStyle(
    fontFamily: _displayFont,
    fontFamilyFallback: _fontFallback,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.9,
    leadingDistribution: TextLeadingDistribution.even,
    letterSpacing: 0,
  );

  static TextStyle h3 = TextStyle(
    fontFamily: _displayFont,
    fontFamilyFallback: _fontFallback,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.8,
    leadingDistribution: TextLeadingDistribution.even,
    letterSpacing: 0,
  );

  // ── Body ────────────────────────────────────────────────────────────────
  static TextStyle bodyLarge = TextStyle(
    fontFamily: _bodyFont,
    fontFamilyFallback: _fontFallback,
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.8,
    leadingDistribution: TextLeadingDistribution.even,
  );

  static TextStyle body = TextStyle(
    fontFamily: _bodyFont,
    fontFamilyFallback: _fontFallback,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.7, // Increased from 1.6
  );

  static TextStyle bodyMedium = TextStyle(
    fontFamily: _bodyFont,
    fontFamilyFallback: _fontFallback,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.6,
  );

  static TextStyle bodySemiBold = TextStyle(
    fontFamily: _bodyFont,
    fontFamilyFallback: _fontFallback,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.6,
  );

  // ── Caption / Label ─────────────────────────────────────────────────────
  static TextStyle caption = TextStyle(
    fontFamily: _bodyFont,
    fontFamilyFallback: _fontFallback,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static TextStyle captionMedium = TextStyle(
    fontFamily: _bodyFont,
    fontFamilyFallback: _fontFallback,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static TextStyle label = TextStyle(
    fontFamily: _bodyFont,
    fontFamilyFallback: _fontFallback,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  // ── Small / Overline ────────────────────────────────────────────────────
  static TextStyle small = TextStyle(
    fontFamily: _bodyFont,
    fontFamilyFallback: _fontFallback,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    height: 1.4,
  );

  static TextStyle overline = TextStyle(
    fontFamily: _displayFont, // Using Display font for authority
    fontFamilyFallback: _fontFallback,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.textMuted,
    height: 1.4,
    letterSpacing: 1.2,
  );

  // ── Buttons ─────────────────────────────────────────────────────────────
  static TextStyle button = TextStyle(
    fontFamily: _bodyFont,
    fontFamilyFallback: _fontFallback,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
    height: 1.2,
    letterSpacing: 0.2,
  );

  static TextStyle buttonSmall = TextStyle(
    fontFamily: _bodyFont,
    fontFamilyFallback: _fontFallback,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
    height: 1.2,
    letterSpacing: 0.2,
  );

  // ── Tab ─────────────────────────────────────────────────────────────────
  static TextStyle tab = TextStyle(
    fontFamily: _bodyFont,
    fontFamilyFallback: _fontFallback,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static TextStyle tabInactive = TextStyle(
    fontFamily: _bodyFont,
    fontFamilyFallback: _fontFallback,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
    height: 1.4,
  );
}
