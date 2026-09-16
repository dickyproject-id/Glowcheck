import 'package:flutter/material.dart';

class AppColors {
  static const Color deepTeal = Color(0xFF006064);
  static const Color salmon = Color(0xFFFF8A65);
  static const Color brightYellow = Color(0xFFFFD54F);
  static const Color mustard = Color(0xFFFFA000);

  // Light Mode
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF2C3E50);
  static const Color softGrey = Color(0xFFEEEEEE);

  // Dark Mode
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color textLight = Color(0xFFE0E0E0);
  static const Color darkGrey = Color(0xFF2C2C2C);
}

class AppTheme {
  // TEMA TERANG
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.backgroundLight,
    primaryColor: AppColors.deepTeal,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.deepTeal,
      brightness: Brightness.light,
      primary: AppColors.deepTeal,
      secondary: AppColors.salmon,
      surface: AppColors.surfaceLight,
      background: AppColors.backgroundLight,
      error: Colors.redAccent,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surfaceLight,
      foregroundColor: AppColors.textDark,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: AppColors.textDark),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.deepTeal,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceLight,
      labelStyle: TextStyle(color: AppColors.textDark.withOpacity(0.6)),
      prefixIconColor: AppColors.deepTeal,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.deepTeal, width: 1.5),
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.textDark),
      bodyMedium: TextStyle(color: AppColors.textDark),
      titleLarge: TextStyle(
        color: AppColors.textDark,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  // TEMA GELAP
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.backgroundDark,
    primaryColor: AppColors.deepTeal,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.deepTeal,
      brightness: Brightness.dark,
      primary: AppColors.deepTeal,
      secondary: AppColors.salmon,
      surface: AppColors.surfaceDark,
      background: AppColors.backgroundDark,
      error: Colors.redAccent,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surfaceDark,
      foregroundColor: AppColors.textLight,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: AppColors.textLight),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.deepTeal,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceDark,
      labelStyle: TextStyle(color: AppColors.textLight.withOpacity(0.6)),
      prefixIconColor: AppColors.salmon,
      suffixIconColor: AppColors.salmon,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.salmon, width: 1.5),
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.textLight),
      bodyMedium: TextStyle(color: AppColors.textLight),
      titleLarge: TextStyle(
        color: AppColors.textLight,
        fontWeight: FontWeight.bold,
      ),
    ),
    iconTheme: const IconThemeData(color: AppColors.textLight),
  );
}
