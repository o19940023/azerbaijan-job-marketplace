import 'package:flutter/material.dart';

class AppTheme {
  // Primary Colors - Modern & Professional
  static const Color primaryColor = Color(0xFF1A73E8); // Vibrant Blue
  static const Color primaryDark = Color(0xFF0D47A1);
  static const Color primaryLight = Color(0xFF64B5F6);

  // Accent Colors
  static const Color accentColor = Color(0xFFFF6D00); // Energetic Orange
  static const Color accentLight = Color(0xFFFFAB40);

  // Status Colors
  static const Color successColor = Color(0xFF00C853);
  static const Color errorColor = Color(0xFFFF1744);
  static const Color warningColor = Color(0xFFFFAB00);
  static const Color infoColor = Color(0xFF2979FF);

  // Neutral Colors
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color surfaceColor = Colors.white;
  static const Color cardColor = Colors.white;
  static const Color dividerColor = Color(0xFFE0E0E0);

  // Text Colors
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Colors.white;

  // Category Colors
  static const Color categoryFood = Color(0xFFFF6B6B);
  static const Color categoryCleaning = Color(0xFF4ECDC4);
  static const Color categoryDelivery = Color(0xFFFFBE0B);
  static const Color categorySecurity = Color(0xFF845EC2);
  static const Color categorySales = Color(0xFFFF9671);
  static const Color categoryDriver = Color(0xFF00C9A7);
  static const Color categoryOther = Color(0xFF6C757D);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, Color(0xFF42A5F5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentColor, Color(0xFFFF8A50)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Shadows
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 20,
          offset: const Offset(0, 10),
          spreadRadius: -5,
        ),
      ];

  static List<BoxShadow> get elevatedShadow => [
        BoxShadow(
          color: primaryColor.withValues(alpha: 0.25),
          blurRadius: 25,
          offset: const Offset(0, 10),
          spreadRadius: -5,
        ),
      ];
      
  static List<BoxShadow> get glassShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  // Border Radius
  static const double radiusSmall = 12;
  static const double radiusMedium = 16;
  static const double radiusLarge = 24;
  static const double radiusXLarge = 32;

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        error: errorColor,
        surface: const Color(0xFFF0F2F5),
        onPrimary: textOnPrimary,
        onSecondary: textOnPrimary,
        onError: textOnPrimary,
        onSurface: textPrimary,
      ),
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      cardColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMedium)),
        margin: EdgeInsets.zero,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 11),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF3F4F6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: errorColor),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(color: textHint, fontSize: 15),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF3F4F6),
        selectedColor: primaryColor.withValues(alpha: 0.12),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 0,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryLight,
        secondary: accentLight,
        error: errorColor,
        surface: Color(0xFF1E1E2E),
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onError: Colors.black,
        onSurface: Color(0xFFE0E0E0),
      ),
      scaffoldBackgroundColor: const Color(0xFF121218),
      cardColor: const Color(0xFF1E1E2E),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E2E),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMedium)),
        margin: EdgeInsets.zero,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1E1E2E),
        selectedItemColor: primaryLight,
        unselectedItemColor: textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 11),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryLight,
          foregroundColor: textPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryLight,
          side: const BorderSide(color: primaryLight, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2A2A3C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: errorColor),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(color: textHint, fontSize: 15),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF2A2A3C),
        selectedColor: primaryLight.withValues(alpha: 0.2),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryLight,
        foregroundColor: textPrimary,
        elevation: 4,
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.1),
        thickness: 1,
        space: 0,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}

extension ThemeColors on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => theme.colorScheme;
  bool get isDarkMode => theme.brightness == Brightness.dark;

  Color get textPrimaryColor => isDarkMode ? Colors.white : AppTheme.textPrimary;
  Color get textSecondaryColor => isDarkMode ? Colors.white70 : AppTheme.textSecondary;
  Color get textHintColor => isDarkMode ? Colors.white54 : AppTheme.textHint;
  Color get cardColor => theme.cardColor;
  Color get scaffoldBackgroundColor => theme.scaffoldBackgroundColor;
  Color get dividerColor => theme.dividerTheme.color ?? AppTheme.dividerColor;
  Color get inputFillColor => theme.inputDecorationTheme.fillColor ?? (isDarkMode ? const Color(0xFF2A2A3C) : const Color(0xFFF3F4F6));
  Color get chipBackgroundColor => theme.chipTheme.backgroundColor ?? (isDarkMode ? const Color(0xFF2A2A3C) : const Color(0xFFF3F4F6));
  Color get iconContainerColor => isDarkMode ? Colors.white.withValues(alpha: 0.1) : AppTheme.primaryColor.withValues(alpha: 0.1);
}
