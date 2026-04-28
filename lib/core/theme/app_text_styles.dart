import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static String? get _displayFont => GoogleFonts.merriweather().fontFamily;
  static String? get _bodyFont => GoogleFonts.dmSans().fontFamily;
  static String? get _monoFont => GoogleFonts.jetBrainsMono().fontFamily;

  static const List<String> _fallback = [
    'NotoSansSinhala',
    'NotoSansTamil',
    'Roboto',
  ];

  static TextStyle displayLarge = TextStyle(
    fontFamily: _displayFont,
    fontFamilyFallback: _fallback,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.inkBlack,
    height: 1.25,
    letterSpacing: 0,
  );

  static TextStyle displaySmall = TextStyle(
    fontFamily: _displayFont,
    fontFamilyFallback: _fallback,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.inkBlack,
    height: 1.3,
    letterSpacing: 0,
  );

  static TextStyle h1 = displayLarge;

  static TextStyle h2 = TextStyle(
    fontFamily: _displayFont,
    fontFamilyFallback: _fallback,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.inkBlack,
    height: 1.3,
    letterSpacing: 0,
  );

  static TextStyle h3 = TextStyle(
    fontFamily: _displayFont,
    fontFamilyFallback: _fallback,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.inkBlack,
    height: 1.35,
    letterSpacing: 0,
  );

  static TextStyle bodyLarge = TextStyle(
    fontFamily: _bodyFont,
    fontFamilyFallback: _fallback,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.inkBlack,
    height: 1.6,
    letterSpacing: 0,
  );

  static TextStyle body = TextStyle(
    fontFamily: _bodyFont,
    fontFamilyFallback: _fallback,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.inkBlack,
    height: 1.6,
    letterSpacing: 0,
  );

  static TextStyle bodyMedium = TextStyle(
    fontFamily: _bodyFont,
    fontFamilyFallback: _fallback,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.inkBlack,
    height: 1.45,
    letterSpacing: 0,
  );

  static TextStyle bodySemiBold = bodyMedium.copyWith(
    fontWeight: FontWeight.w600,
  );

  static TextStyle caption = TextStyle(
    fontFamily: _bodyFont,
    fontFamilyFallback: _fallback,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.inkMid,
    height: 1.5,
    letterSpacing: 0,
  );

  static TextStyle captionMedium = caption.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );

  static TextStyle label = TextStyle(
    fontFamily: _bodyFont,
    fontFamilyFallback: _fallback,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.inkBlack,
    height: 1,
    letterSpacing: 0,
  );

  static TextStyle small = TextStyle(
    fontFamily: _bodyFont,
    fontFamilyFallback: _fallback,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.inkLight,
    height: 1.35,
    letterSpacing: 0,
  );

  static TextStyle overline = TextStyle(
    fontFamily: _bodyFont,
    fontFamilyFallback: _fallback,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.inkLight,
    height: 1.4,
    letterSpacing: 0.8,
  );

  static TextStyle button = TextStyle(
    fontFamily: _bodyFont,
    fontFamilyFallback: _fallback,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
    height: 1,
    letterSpacing: 0,
  );

  static TextStyle buttonSmall = button.copyWith(fontSize: 13);

  static TextStyle tab = TextStyle(
    fontFamily: _bodyFont,
    fontFamilyFallback: _fallback,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.brandGreen,
    height: 1.4,
    letterSpacing: 0,
  );

  static TextStyle tabInactive = tab.copyWith(
    color: AppColors.inkLight,
    fontWeight: FontWeight.w500,
  );

  static TextStyle monoMedium = TextStyle(
    fontFamily: _monoFont,
    fontFamilyFallback: _fallback,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.inkMid,
    height: 1.5,
    letterSpacing: 0,
  );
}
