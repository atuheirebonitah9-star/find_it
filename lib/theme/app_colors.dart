// lib/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // ============ PRIMARY - Navy Blue ============
  static const Color primary = Color(0xFF1A365D);
  static const Color primaryLight = Color(0xFF2B4C7E);
  static const Color primaryDark = Color(0xFF0D1F3C);
  static const Color primaryGradientStart = Color(0xFF1A365D);
  static const Color primaryGradientEnd = Color(0xFF2B4C7E);
  
  // ============ SECONDARY - Teal ============
  static const Color secondary = Color(0xFF0D9488);
  static const Color secondaryLight = Color(0xFF2DD4BF);
  static const Color secondaryDark = Color(0xFF0F766E);
  
  // ============ ACCENT - Warm Amber ============
  static const Color accent = Color(0xFFD97706);
  static const Color accentLight = Color(0xFFF59E0B);
  static const Color accentDark = Color(0xFFB45309);
  
  // ============ STATUS COLORS ============
  static const Color lostColor = Color(0xFFDC2626);
  static const Color foundColor = Color(0xFF059669);
  
  // Status backgrounds
  static const Color lostBg = Color(0xFFFEE2E2);
  static const Color foundBg = Color(0xFFD1FAE5);
  
  // ============ NEUTRALS ============
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color text = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF334155);
  static const Color muted = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFF1F5F9);
  
  // ============ SHADOWS ============
  static List<BoxShadow> cardShadow = const [
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 12,
      offset: Offset(0, 4),
      spreadRadius: 0,
    ),
  ];
  
  static List<BoxShadow> elevatedShadow = const [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 16,
      offset: Offset(0, 6),
      spreadRadius: 0,
    ),
  ];
  
  static List<BoxShadow> softShadow = const [
    BoxShadow(
      color: Color(0x08000000),
      blurRadius: 8,
      offset: Offset(0, 2),
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
  
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accentLight],
  );
}

// Extension for easy opacity usage
extension AppColorsExtension on Color {
  Color withOpacity(double opacity) {
    return this.withOpacity(opacity);
  }
}