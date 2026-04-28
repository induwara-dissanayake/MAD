import 'package:flutter/material.dart';

/// Village Connect design tokens.
///
/// The primary names follow DESIGN.md. The aliases at the bottom keep older
/// screens compiling while they are migrated to the newer token names.
class AppColors {
  AppColors._();

  static const Color brandGreen = Color(0xFF1A6B3C);
  static const Color brandGreenLight = Color(0xFF2E8B57);
  static const Color brandGreenSurface = Color(0xFFE8F5EE);
  static const Color brandGreenBorder = Color(0xFFB2DFCB);

  static const Color inkBlack = Color(0xFF1C1B18);
  static const Color inkDark = Color(0xFF3A3936);
  static const Color inkMid = Color(0xFF5C5B56);
  static const Color inkLight = Color(0xFF8A8880);

  static const Color surfaceParchment = Color(0xFFF6F4ED);
  static const Color surfaceIvory = Color(0xFFFAFAF6);
  static const Color surfaceWarmSand = Color(0xFFEAE8DF);
  static const Color surfaceDark = Color(0xFF2B2B28);

  static const Color statusApproved = Color(0xFF1A6B3C);
  static const Color statusPending = Color(0xFFB07A1A);
  static const Color statusReview = Color(0xFF1A5A8A);
  static const Color statusRejected = Color(0xFFB53333);
  static const Color focusBlue = Color(0xFF3898EC);
  static const Color errorRed = Color(0xFFB53333);
  static const Color successGreen = Color(0xFF2D7A4F);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandGreen, brandGreenLight],
  );

  static const LinearGradient heroGradient = primaryGradient;

  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [surfaceParchment, surfaceIvory],
  );

  static const List<BoxShadow> shadowLow = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> shadowMedium = [
    BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 4)),
  ];

  // Backwards-compatible aliases.
  static const Color primary = brandGreen;
  static const Color primaryLight = brandGreenSurface;
  static const Color primaryDark = Color(0xFF104528);
  static const Color secondary = statusReview;
  static const Color secondaryLight = Color(0xFFDAE8F5);
  static const Color accent = statusPending;
  static const Color accentLight = Color(0xFFFDF3DA);

  static const Color background = surfaceParchment;
  static const Color surface = surfaceIvory;
  static const Color surfaceContainerLow = surfaceWarmSand;
  static const Color surfaceContainerLowest = surfaceIvory;
  static const Color card = surfaceIvory;
  static const Color surfaceGrey = surfaceWarmSand;
  static const Color secondarySurface = brandGreenSurface;

  static const Color textPrimary = inkBlack;
  static const Color textSecondary = inkMid;
  static const Color textMuted = inkLight;
  static const Color textOnPrimary = Colors.white;

  static const Color success = statusApproved;
  static const Color successLight = Color(0xFFD4EDE0);
  static const Color warning = statusPending;
  static const Color warningLight = Color(0xFFFDF3DA);
  static const Color error = errorRed;
  static const Color errorLight = Color(0xFFFBDADA);
  static const Color info = statusReview;
  static const Color infoLight = Color(0xFFDAE8F5);

  static const Color border = surfaceWarmSand;
  static const Color divider = surfaceWarmSand;
  static const Color disabled = inkLight;
  static const Color disabledBackground = surfaceWarmSand;

  static final Color shadow = const Color(0xFF000000).withValues(alpha: 0.08);
  static final Color shadowLight = const Color(
    0xFF000000,
  ).withValues(alpha: 0.04);

  static const Color accentBlue = infoLight;
  static const Color accentGreen = successLight;
  static const Color accentRed = errorLight;
  static const Color accentYellow = warningLight;
  static const Color accentPurple = Color(0xFFEDE7F6);
}
