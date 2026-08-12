import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const kPrimary     = Color(0xFFF97316);
  static const kBackground  = Color(0xFF0D0F14);
  static const kSurface     = Color(0xFF161B22);
  static const kCard        = Color(0xFF1C2333);
  static const kSuccess     = Color(0xFF22C55E);
  static const kWarning     = Color(0xFFEAB308);
  static const kError       = Color(0xFFEF4444);
  static const kTextPrimary = Color(0xFFF0F6FF);
  static const kTextMuted   = Color(0xFF8B949E);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: kPrimary,
        surface: kBackground,   // ← 'background' removed; use surface
        error: kError,
      ),
      scaffoldBackgroundColor: kBackground,
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
        bodyLarge:  GoogleFonts.outfit(color: kTextPrimary),
        bodyMedium: GoogleFonts.outfit(color: kTextPrimary),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: kSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.bold),
        iconTheme: IconThemeData(color: kTextPrimary),
      ),
      cardTheme: CardThemeData(                 // ← CardTheme → CardThemeData
        color: kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: kSurface,
        selectedItemColor: kPrimary,
        unselectedItemColor: kTextMuted,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: kSurface,
        selectedColor: kPrimary,
        labelStyle: const TextStyle(color: kTextPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: kSurface,
        labelStyle: const TextStyle(color: kTextMuted),
        hintStyle: const TextStyle(color: kTextMuted),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
