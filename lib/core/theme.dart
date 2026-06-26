import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final veilLightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: const Color(0xFFF5F5F5),
  colorScheme: const ColorScheme.light(
    surface: Colors.white,
    primary: Color(0xFF4ADE80),
    onSurface: Color(0xFF1A1A1A),
    outline: Color(0xFFE0E0E0),
    error: Color(0xFFEF4444),
  ),
  textTheme: TextTheme(
    headlineLarge: GoogleFonts.spaceMono(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A)),
    headlineMedium: GoogleFonts.spaceMono(fontSize: 22, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A)),
    bodyLarge: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF1A1A1A), height: 1.4),
    bodyMedium: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1A1A1A), height: 1.4),
    labelLarge: GoogleFonts.spaceMono(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
  ),
  cardTheme: CardTheme(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), color: Colors.white),
  elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4ADE80), foregroundColor: const Color(0xFF0A0A0F), elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
  inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4ADE80), width: 2)), contentPadding: const EdgeInsets.all(16)),
  appBarTheme: const AppBarTheme(backgroundColor: Colors.white, foregroundColor: Color(0xFF1A1A1A), elevation: 0, centerTitle: true),
);

final veilDarkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF0A0A0F),
  colorScheme: const ColorScheme.dark(
    surface: Color(0xFF14141F),
    primary: Color(0xFF4ADE80),
    onSurface: Color(0xFFE0E0E0),
    outline: Color(0xFF2A2A3A),
    error: Color(0xFFEF4444),
  ),
  textTheme: TextTheme(
    headlineLarge: GoogleFonts.spaceMono(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFFE0E0E0)),
    headlineMedium: GoogleFonts.spaceMono(fontSize: 22, fontWeight: FontWeight.w600, color: const Color(0xFFE0E0E0)),
    bodyLarge: GoogleFonts.inter(fontSize: 16, color: const Color(0xFFE0E0E0), height: 1.4),
    bodyMedium: GoogleFonts.inter(fontSize: 14, color: const Color(0xFFE0E0E0), height: 1.4),
    labelLarge: GoogleFonts.spaceMono(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF0A0A0F)),
  ),
  cardTheme: CardTheme(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), color: const Color(0xFF1A1A26)),
  elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4ADE80), foregroundColor: const Color(0xFF0A0A0F), elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
  inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: const Color(0xFF14141F), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2A2A3A))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2A2A3A))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4ADE80), width: 2)), contentPadding: const EdgeInsets.all(16)),
  appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF0A0A0F), foregroundColor: Color(0xFFE0E0E0), elevation: 0, centerTitle: true),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(backgroundColor: Color(0xFF0A0A0F)),
);