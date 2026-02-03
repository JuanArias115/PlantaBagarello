import 'package:flutter/material.dart';

class AppTheme {
  static const Color coffeeDark = Color(0xFF4E342E);
  static const Color leafGreen = Color(0xFF2E7D32);
  static const Color cream = Color(0xFFF5F5DC);
  static const Color sand = Color(0xFFD7CCC8);

  static ThemeData get theme {
    final colorScheme = ColorScheme.fromSeed(seedColor: coffeeDark).copyWith(
      primary: coffeeDark,
      secondary: leafGreen,
      surface: cream,
      background: cream,
    );

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: cream,
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: sand.withOpacity(0.25),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: coffeeDark,
        foregroundColor: cream,
      ),
    );
  }
}
