import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static const String? appFontFamily = null;
  static const List<String>? fontFallback = null;

  static const TextHeightBehavior textHeightBehavior = TextHeightBehavior(
    applyHeightToFirstAscent: true,
    applyHeightToLastDescent: true,
    leadingDistribution: TextLeadingDistribution.proportional,
  );

  static StrutStyle strutStyle(double fontSize, {double height = 1.45}) {
    return StrutStyle(
      fontFamily: appFontFamily,
      fontFamilyFallback: fontFallback,
      fontSize: fontSize,
      height: height,
      leading: 0.25,
      forceStrutHeight: true,
    );
  }

  static TextStyle _style({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    required double height,
  }) {
    return TextStyle(
      fontFamily: appFontFamily,
      fontFamilyFallback: fontFallback,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      leadingDistribution: TextLeadingDistribution.proportional,
    );
  }

  static TextStyle displayLarge = _style(
    fontSize: 28,
    fontWeight: FontWeight.w400,
    color: AppColors.inkBlack,
    height: 1.55,
  );

  static TextStyle displaySmall = _style(
    fontSize: 22,
    fontWeight: FontWeight.w400,
    color: AppColors.inkBlack,
    height: 1.55,
  );

  static TextStyle h1 = displayLarge;

  static TextStyle h2 = _style(
    fontSize: 22,
    fontWeight: FontWeight.w400,
    color: AppColors.inkBlack,
    height: 1.55,
  );

  static TextStyle h3 = _style(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: AppColors.inkBlack,
    height: 1.55,
  );

  static TextStyle bodyLarge = _style(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.inkBlack,
    height: 1.6,
  );

  static TextStyle body = _style(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.inkBlack,
    height: 1.58,
  );

  static TextStyle bodyMedium = _style(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.inkBlack,
    height: 1.58,
  );

  static TextStyle bodySemiBold = bodyMedium;

  static TextStyle caption = _style(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.inkMid,
    height: 1.5,
  );

  static TextStyle captionMedium = caption.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  static TextStyle label = _style(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.inkBlack,
    height: 1.55,
  );

  static TextStyle small = _style(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.inkLight,
    height: 1.55,
  );

  static TextStyle overline = _style(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.inkLight,
    height: 1.55,
  );

  static TextStyle button = _style(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textOnPrimary,
    height: 1.55,
  );

  static TextStyle buttonSmall = button.copyWith(fontSize: 13);

  static TextStyle tab = _style(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.brandGreen,
    height: 1.55,
  );

  static TextStyle tabInactive = tab.copyWith(
    color: AppColors.inkLight,
    fontWeight: FontWeight.w400,
  );

  static TextStyle monoMedium = _style(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.inkMid,
    height: 1.5,
  );
}
