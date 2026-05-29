import 'package:flutter/material.dart';

class AppTheme {
  static const Color brand = Color(0xFF0F6FDB);
  static const Color brandDark = Color(0xFF0B4EA2);
  static const Color brandSoft = Color(0xFFEAF3FF);
  static const Color brandTint = Color(0xFFF4F8FF);
  static const Color accent = Color(0xFF16B8A6);
  static const Color accentSoft = Color(0xFFE8FBF7);
  static const Color background = Color(0xFFF5F7FB);
  static const Color backgroundAlt = Color(0xFFECF2FA);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF10233F);
  static const Color textSecondary = Color(0xFF667085);
  static const Color danger = Color(0xFFE5484D);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);

  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(24));
  static const BorderRadius fieldRadius = BorderRadius.all(Radius.circular(18));

  static ThemeData lightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: brand,
      brightness: Brightness.light,
      primary: brand,
      secondary: accent,
      surface: surface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: brand),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: textPrimary,
        centerTitle: false,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: const CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: cardRadius),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brand,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: brand,
          side: const BorderSide(color: Color(0xFFD9E6F8)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brand,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF9FBFF),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFD7E2F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFD7E2F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: brand, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: danger, width: 1.8),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textSecondary),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: brandSoft,
        selectedColor: brand,
        disabledColor: const Color(0xFFE6EEF8),
        labelStyle: const TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: textPrimary,
        unselectedLabelColor: textSecondary,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: brand, width: 3),
        ),
        labelStyle: TextStyle(fontWeight: FontWeight.w700),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
        dividerColor: Color(0xFFE6ECF5),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimary,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        behavior: SnackBarBehavior.floating,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? brand : null,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        side: const BorderSide(color: Color(0xFFC9D6E8)),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFE6ECF5)),
      iconTheme: const IconThemeData(color: textPrimary),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: brand,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: brandSoft,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: textPrimary,
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: textPrimary,
          height: 1.1,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: textPrimary,
          height: 1.15,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: textPrimary,
          height: 1.4,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: textSecondary,
          height: 1.45,
        ),
      ),
      splashFactory: InkSparkle.constantTurbulenceSeedSplashFactory,
    );
  }
}
