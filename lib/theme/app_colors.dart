import 'package:flutter/material.dart';

class AppColors {
  // Primary colors - Warm orange theme
  static const Color primary = Color(0xFFFF6B35);
  static const Color primaryLight = Color(0xFFFF8A5C);
  static const Color primaryDark = Color(0xFFE55A2B);
  static const Color primaryGradientStart = Color(0xFFFF6B35);
  static const Color primaryGradientEnd = Color(0xFFFF8A5C);
  
  // Status colors
  static const Color secondary = Color(0xFF2ECC71); // Found/Green
  static const Color accent = Color(0xFFE74C3C); // Lost/Red
  
  // Status backgrounds
  static const Color lostBg = Color(0xFFFFEBEE);
  static const Color foundBg = Color(0xFFE8F8F0);
  
  // Neutrals - Light theme
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Colors.white;
  static const Color text = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF4A4A5A);
  static const Color muted = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFF0F0F0);
  
  // Shadows
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
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryGradientStart, primaryGradientEnd],
  );
  
  static const LinearGradient cardGradientLost = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFEBEE), Color(0xFFFFF5F5)],
  );
  
  static const LinearGradient cardGradientFound = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE8F8F0), Color(0xFFF0FAF5)],
  );
}

// Extension for easy opacity usage
extension AppColorsExtension on Color {
  Color withOpacity(double opacity) {
    return this.withOpacity(opacity);
  }
}