import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const _bg = Color(0xFF0B1020);
  static const _card = Color(0xFF151C2F);
  static const _accent = Color(0xFF3B82F6);
  static const _success = Color(0xFF22C55E);
  static const _warning = Color(0xFFF59E0B);
  static const _danger = Color(0xFFEF4444);

  static ThemeData get darkTheme {
    final textTheme = GoogleFonts.interTextTheme(
      ThemeData.dark().textTheme,
    );

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _bg,
      textTheme: textTheme,
      colorScheme: const ColorScheme.dark(
        primary: _accent,
        secondary: _warning,
        surface: _card,
        error: _danger,
      ),
      cardTheme: CardThemeData(
        color: _card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF11182A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _accent, width: 1.2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      useMaterial3: true,
    );
  }

  static Color get success => _success;
  static Color get warning => _warning;
  static Color get danger => _danger;
}