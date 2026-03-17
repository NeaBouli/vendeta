import 'package:flutter/material.dart';

class AppColors {
  static const bg      = Color(0xFF0D1117);
  static const bg2     = Color(0xFF161B22);
  static const bg3     = Color(0xFF21262D);
  static const border  = Color(0xFF30363D);
  static const text    = Color(0xFFC9D1D9);
  static const muted   = Color(0xFF8B949E);
  static const orange  = Color(0xFFF97316);
  static const blue    = Color(0xFF3B82F6);
  static const green   = Color(0xFF22C55E);
  static const red     = Color(0xFFEF4444);
  static const amber   = Color(0xFFEAB308);
}

class AppTheme {
  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      primary:   AppColors.orange,
      secondary: AppColors.blue,
      surface:   AppColors.bg2,
      error:     AppColors.red,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg2,
      foregroundColor: AppColors.text,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppColors.text,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.bg2,
      selectedItemColor: AppColors.orange,
      unselectedItemColor: AppColors.muted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: AppColors.bg2,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.border, width: .5),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bg3,
      hintStyle: const TextStyle(color: AppColors.muted, fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border, width: .5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border, width: .5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.blue, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.border, thickness: .5),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(color: AppColors.text, fontSize: 28, fontWeight: FontWeight.w700),
      headlineMedium: TextStyle(color: AppColors.text, fontSize: 22, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(color: AppColors.text, fontSize: 18, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: AppColors.text, fontSize: 16),
      bodyMedium: TextStyle(color: AppColors.muted, fontSize: 14),
      bodySmall: TextStyle(color: AppColors.muted, fontSize: 12),
    ),
  );
}
