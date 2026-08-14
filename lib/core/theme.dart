import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

class VeilColors {
  static const Color primary = Color(0xFF6C5CE7);
  static const Color primaryLight = Color(0xFF8B7CF0);
  static const Color primaryDark = Color(0xFF4A3DB8);
  static const Color primaryGlow = Color(0xFF6C5CE7);
  
  static const Color background = Color(0xFF0A0A0F);
  static const Color backgroundSecondary = Color(0xFF14141F);
  static const Color surface = Color(0xFF1A1A2E);
  static const Color surfaceLight = Color(0xFF24243E);
  
  static const Color textPrimary = Color(0xFFF4F4F5);
  static const Color textSecondary = Color(0xFFA1A1AA);
  static const Color textMuted = Color(0xFF71717A);
  
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF0A0A0F), Color(0xFF14141F)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static LinearGradient glassGradient() {
    return LinearGradient(
      colors: [
        Colors.white.withOpacity(0.05),
        Colors.white.withOpacity(0.02),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}

class GlassStyle {
  static BoxDecoration glass() {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.white.withOpacity(0.05),
          Colors.white.withOpacity(0.02),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Colors.white.withOpacity(0.05),
        width: 1,
      ),
    );
  }
  
  static BoxDecoration glassWithBorder({Color? borderColor}) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.white.withOpacity(0.08),
          Colors.white.withOpacity(0.02),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: borderColor ?? Colors.white.withOpacity(0.05),
        width: 1,
      ),
    );
  }
}

class NeonStyle {
  static BoxDecoration glowBox({Color? color}) {
    final glowColor = color ?? VeilColors.primary;
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          glowColor.withOpacity(0.1),
          glowColor.withOpacity(0.02),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: glowColor.withOpacity(0.2),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: glowColor.withOpacity(0.15),
          blurRadius: 30,
          spreadRadius: 5,
        ),
      ],
    );
  }

  static TextStyle neonText({
    required Color color,
    double fontSize = 24,
    FontWeight fontWeight = FontWeight.bold,
  }) {
    return TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      shadows: [
        Shadow(
          color: color.withOpacity(0.5),
          blurRadius: 20,
        ),
        Shadow(
          color: color.withOpacity(0.3),
          blurRadius: 40,
        ),
      ],
    );
  }
}

// ============================================================
// 🌗 СВЕТЛАЯ ТЕМА
// ============================================================

final veilLightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  fontFamily: 'Inter',
  
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF6C5CE7),
    secondary: Color(0xFF8B7CF0),
    surface: Colors.white,
    background: Color(0xFFF8F9FA),
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Color(0xFF1A1A1A),
    onBackground: Color(0xFF1A1A1A),
    error: Color(0xFFEF4444),
    outline: Color(0xFFE5E7EB),
  ),
  
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
    foregroundColor: Color(0xFF1A1A1A),
    scrolledUnderElevation: 0,
    systemOverlayStyle: SystemUiOverlayStyle.dark,
  ),
  
  cardTheme: CardTheme(
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(
        color: Colors.grey.withOpacity(0.1),
        width: 1,
      ),
    ),
    shadowColor: Colors.black.withOpacity(0.05),
  ),
  
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF6C5CE7),
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    ),
  ),
  
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFF3F4F6),
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
      borderSide: const BorderSide(
        color: Color(0xFF6C5CE7),
        width: 2,
      ),
    ),
    contentPadding: const EdgeInsets.all(16),
    hintStyle: const TextStyle(
      color: Color(0xFF9CA3AF),
      fontSize: 15,
    ),
  ),
  
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: Color(0xFF1A1A1A),
      fontFamily: 'Inter',
      letterSpacing: -0.5,
    ),
    headlineLarge: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: Color(0xFF1A1A1A),
      fontFamily: 'Inter',
      letterSpacing: -0.5,
    ),
    headlineMedium: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: Color(0xFF1A1A1A),
      fontFamily: 'Inter',
      letterSpacing: -0.3,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      color: Color(0xFF1A1A1A),
      fontFamily: 'Inter',
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      color: Color(0xFF4B5563),
      fontFamily: 'Inter',
      height: 1.5,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      color: Color(0xFF9CA3AF),
      fontFamily: 'Inter',
      height: 1.5,
    ),
    labelLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      fontFamily: 'Inter',
    ),
  ),
  
  listTileTheme: ListTileThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    tileColor: Colors.white,
  ),
  
  dialogTheme: DialogTheme(
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
    ),
    elevation: 20,
    shadowColor: Colors.black.withOpacity(0.1),
  ),
  
  snackBarTheme: const SnackBarThemeData(
    backgroundColor: Colors.white,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
    elevation: 10,
    contentTextStyle: TextStyle(
      color: Color(0xFF1A1A1A),
      fontSize: 14,
    ),
  ),
  
  scaffoldBackgroundColor: const Color(0xFFF8F9FA),
);

// ============================================================
// 🌗 ТЁМНАЯ ТЕМА
// ============================================================

final veilDarkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  fontFamily: 'Inter',
  
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF6C5CE7),
    secondary: Color(0xFF8B7CF0),
    surface: Color(0xFF1A1A2E),
    background: Color(0xFF0A0A0F),
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Color(0xFFF4F4F5),
    onBackground: Color(0xFFF4F4F5),
    error: Color(0xFFEF4444),
    outline: Color(0xFF2A2A3E),
  ),
  
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    centerTitle: true,
    foregroundColor: Color(0xFFF4F4F5),
    scrolledUnderElevation: 0,
    systemOverlayStyle: SystemUiOverlayStyle.light,
  ),
  
  cardTheme: CardTheme(
    elevation: 0,
    color: Color(0xFF1A1A2E).withOpacity(0.6),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(
        color: Colors.white.withOpacity(0.05),
        width: 1,
      ),
    ),
    shadowColor: Color(0xFF6C5CE7).withOpacity(0.1),
  ),
  
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF6C5CE7),
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    ),
  ),
  
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF1A1A2E).withOpacity(0.5),
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
      borderSide: const BorderSide(
        color: Color(0xFF6C5CE7),
        width: 2,
      ),
    ),
    contentPadding: const EdgeInsets.all(16),
    hintStyle: const TextStyle(
      color: Color(0xFF71717A),
      fontSize: 15,
    ),
  ),
  
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: Color(0xFFF4F4F5),
      fontFamily: 'Inter',
      letterSpacing: -0.5,
    ),
    headlineLarge: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: Color(0xFFF4F4F5),
      fontFamily: 'Inter',
      letterSpacing: -0.5,
    ),
    headlineMedium: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: Color(0xFFF4F4F5),
      fontFamily: 'Inter',
      letterSpacing: -0.3,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      color: Color(0xFFF4F4F5),
      fontFamily: 'Inter',
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      color: Color(0xFFA1A1AA),
      fontFamily: 'Inter',
      height: 1.5,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      color: Color(0xFF71717A),
      fontFamily: 'Inter',
      height: 1.5,
    ),
    labelLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      fontFamily: 'Inter',
    ),
  ),
  
  listTileTheme: ListTileThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
  ),
  
  dialogTheme: DialogTheme(
    backgroundColor: Color(0xFF1A1A2E).withOpacity(0.9),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
    ),
    elevation: 20,
    shadowColor: Color(0xFF6C5CE7).withOpacity(0.2),
  ),
  
  snackBarTheme: const SnackBarThemeData(
    backgroundColor: Color(0xFF1A1A2E),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
    elevation: 10,
    contentTextStyle: TextStyle(
      color: Color(0xFFF4F4F5),
      fontSize: 14,
    ),
  ),
  
  scaffoldBackgroundColor: const Color(0xFF0A0A0F),
);