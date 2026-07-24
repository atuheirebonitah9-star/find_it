// lib/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // ============ PRIMARY - Signal Orange ============
  static const Color primary = Color(0xFFFF8C00);
  static const Color primaryLight = Color(0xFFFFA033);
  static const Color primaryDark = Color(0xFFCC7000);
  static const Color primaryGradientStart = Color(0xFFFF8C00);
  static const Color primaryGradientEnd = Color(0xFFFFA033);
  
  // ============ SECONDARY - Green (Found) ============
  static const Color secondary = Color(0xFF00C853);
  static const Color secondaryLight = Color(0xFF69F0AE);
  static const Color secondaryDark = Color(0xFF009624);
  
  // ============ STATUS COLORS ============
  static const Color lostColor = Color(0xFFFF8C00);
  static const Color foundColor = Color(0xFF00C853);
  
  // Status backgrounds - FIXED: Remove const, use static getter
  static Color get lostBg => const Color(0xFFFF8C00).withOpacity(0.15);
  static Color get foundBg => const Color(0xFF00C853).withOpacity(0.15);
  
  // ============ ERROR COLORS ============
  static const Color error = Color(0xFFFFB4AB);
  static const Color onError = Color(0xFF690005);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color onErrorContainer = Color(0xFFFFDAD6);
  
  // ============ SURFACE COLORS (Dark Theme) ============
  static const Color background = Color(0xFF131313);
  static const Color onBackground = Color(0xFFE2E2E2);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color surfaceDim = Color(0xFF131313);
  static const Color surfaceBright = Color(0xFF393939);
  static const Color surfaceContainerLowest = Color(0xFF0E0E0E);
  static const Color surfaceContainerLow = Color(0xFF1B1B1B);
  static const Color surfaceContainer = Color(0xFF1F1F1F);
  static const Color surfaceContainerHigh = Color(0xFF2A2A2A);
  static const Color surfaceContainerHighest = Color(0xFF353535);
  static const Color surfaceLight = Color(0xFF2A2A2A);
  static const Color onSurface = Color(0xFFE2E2E2);
  static const Color onSurfaceVariant = Color(0xFFDDC1AE);
  static const Color inverseSurface = Color(0xFFE2E2E2);
  static const Color inverseOnSurface = Color(0xFF303030);
  static const Color surfaceTint = Color(0xFFFFB77D);
  
  // ============ NEUTRALS ============
  static const Color text = Color(0xFFE2E2E2);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color muted = Color(0xFF808080);
  static const Color textTertiary = Color(0xFF666666);
  static const Color border = Color(0xFF333333);
  static const Color divider = Color(0xFF1A1A1A);
  
  // ============ ON PRIMARY (for black text on orange) ============
  static const Color onPrimary = Color(0xFF000000);
  
  // ============ OUTLINE ============
  static const Color outline = Color(0xFFA48C7A);
  static const Color outlineVariant = Color(0xFF564334);
  
  // ============ SHADOWS ============
  static List<BoxShadow> cardShadow = const [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 12,
      offset: Offset(0, 4),
      spreadRadius: 0,
    ),
  ];
  
  static List<BoxShadow> elevatedShadow = const [
    BoxShadow(
      color: Color(0x2A000000),
      blurRadius: 16,
      offset: Offset(0, 6),
      spreadRadius: 0,
    ),
  ];
  
  static List<BoxShadow> softShadow = const [
    BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 8,
      offset: Offset(0, 2),
      spreadRadius: 0,
    ),
  ];
  
  static List<BoxShadow> orangeGlow = const [
    BoxShadow(
      color: Color(0x26FF8C00),
      blurRadius: 16,
      offset: Offset(0, 4),
      spreadRadius: 0,
    ),
  ];
  
  // ============ GRADIENTS ============
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryGradientStart, primaryGradientEnd],
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, secondaryLight],
  );
  
  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1A1A), Color(0xFF1F1F1F)],
  );
  
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0A0A0A), Color(0xFF1A1A1A)],
  );
}

extension AppColorsExtension on Color {
  Color withOpacity(double opacity) {
    return this.withOpacity(opacity);
  }
}