import 'package:flutter/material.dart';

final veilLightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  fontFamily: 'Roboto',
  scaffoldBackgroundColor: const Color(0xFFF8F9FA),
  colorScheme: const ColorScheme.light(
    surface: Colors.white,
    primary: Color(0xFF10B981),
    onSurface: Color(0xFF111827),
    outline: Color(0xFFE5E7EB),
    error: Color(0xFFEF4444),
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF111827), fontFamily: 'RobotoMono'),
    headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Color(0xFF111827), fontFamily: 'RobotoMono'),
    bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF111827), height: 1.5),
    bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF111827), height: 1.5),
    labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white, fontFamily: 'RobotoMono'),
  ),
  cardTheme: CardTheme(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), color: Colors.white),
  elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)))),
  inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: const Color(0xFFF3F4F6), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF10B981), width: 2)), contentPadding: const EdgeInsets.all(16)),
  appBarTheme: const AppBarTheme(backgroundColor: Colors.white, foregroundColor: Color(0xFF111827), elevation: 0, centerTitle: true, scrolledUnderElevation: 1),
);

final veilDarkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  fontFamily: 'Roboto',
  scaffoldBackgroundColor: const Color(0xFF09090B),
  colorScheme: const ColorScheme.dark(
    surface: Color(0xFF18181B),
    primary: Color(0xFF10B981),
    onSurface: Color(0xFFF4F4F5),
    outline: Color(0xFF27272A),
    error: Color(0xFFEF4444),
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFF4F4F5), fontFamily: 'RobotoMono'),
    headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Color(0xFFF4F4F5), fontFamily: 'RobotoMono'),
    bodyLarge: TextStyle(fontSize: 16, color: Color(0xFFF4F4F5), height: 1.5),
    bodyMedium: TextStyle(fontSize: 14, color: Color(0xFFF4F4F5), height: 1.5),
    labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF09090B), fontFamily: 'RobotoMono'),
  ),
  cardTheme: CardTheme(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), color: const Color(0xFF18181B)),
  elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: const Color(0xFF09090B), elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)))),
  inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: const Color(0xFF18181B), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF10B981), width: 2)), contentPadding: const EdgeInsets.all(16)),
  appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF09090B), foregroundColor: Color(0xFFF4F4F5), elevation: 0, centerTitle: true, scrolledUnderElevation: 1),
);