/// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  // ============ TYPOGRAPHY ============
  static const TextStyle heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
    height: 1.2,
    letterSpacing: -0.5,
  );
  
  static const TextStyle heading2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
    height: 1.3,
    letterSpacing: -0.3,
  );
  
  static const TextStyle heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
    height: 1.4,
  );
  
  static const TextStyle heading4 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
    height: 1.4,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.text,
    height: 1.5,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.muted,
    height: 1.4,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: AppColors.muted,
    height: 1.4,
    letterSpacing: 0.5,
  );
  
  static const TextStyle buttonText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.2,
  );
  
  static const TextStyle labelText = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    height: 1.2,
  );

  // ============ LIGHT THEME ============
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Inter',
      
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.primary,
        surface: AppColors.surface,
        error: AppColors.accent,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.text,
        onError: Colors.white,
      ),
      
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.text,
          height: 1.3,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: AppColors.text),
        toolbarHeight: 72,
        scrolledUnderElevation: 0,
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        hintStyle: bodyMedium.copyWith(color: AppColors.muted),
        labelStyle: labelText,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        prefixIconColor: AppColors.muted,
        suffixIconColor: AppColors.muted,
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          textStyle: buttonText,
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: AppColors.border),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(30)),
        ),
      ),
      
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.background,
        selectedColor: AppColors.primary.withOpacity(0.1),
        labelStyle: bodyMedium,
        secondaryLabelStyle: bodyMedium.copyWith(fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        side: const BorderSide(color: AppColors.border),
      ),
      
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        elevation: 8,
      ),
      
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.text,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),
      
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionHandleColor: AppColors.primary,
      ),
      
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 0,
      ),
      
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: MaterialStateProperty.all(AppColors.muted.withOpacity(0.3)),
        radius: const Radius.circular(10),
        thickness: MaterialStateProperty.all(4),
      ),
      
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.border,
        circularTrackColor: AppColors.border,
      ),
      
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 8,
      ),
    );
  }

  // ============ DARK THEME ============
  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: const Color(0xFF121212),
      fontFamily: 'Inter',
      
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.primary,
        surface: Color(0xFF1E1E1E),
        error: AppColors.accent,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onError: Colors.white,
      ),
      
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          height: 1.3,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: Colors.white),
        toolbarHeight: 72,
        scrolledUnderElevation: 0,
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        hintStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Color(0xFF9CA3AF),
          height: 1.5,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        prefixIconColor: const Color(0xFF9CA3AF),
        suffixIconColor: const Color(0xFF9CA3AF),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      cardTheme: const CardThemeData(
        color: Color(0xFF1E1E1E),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF2A2A2A),
        selectedColor: AppColors.primary.withOpacity(0.2),
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Colors.white,
        ),
        secondaryLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        side: const BorderSide(color: Color(0xFF333333)),
      ),
      
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      
      dialogTheme: const DialogThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        elevation: 8,
      ),
      
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF2A2A2A),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),
      
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionHandleColor: AppColors.primary,
      ),
      
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: Color(0xFF333333),
        circularTrackColor: Color(0xFF333333),
      ),
    );
  }
}

// ============ THEME EXTENSIONS ============
extension ThemeExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}