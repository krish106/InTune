import 'package:flutter/material.dart';

class VelocityTheme {
  // Colors
  static const deepNavy = Color(0xFF0F172A);
  static const electricCyan = Color(0xFF06B6D4);
  static const neonPurple = Color(0xFF8B5CF6);
  static const cardBackground = Color(0xFF1E293B);
  static const glassBackground = Color(0x33FFFFFF);
  
  // Gradients
  static const cyberGradient = LinearGradient(
    colors: [electricCyan, neonPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const glowGradient = LinearGradient(
    colors: [
      Color(0x4006B6D4),
      Color(0x408B5CF6),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Shadows
  static BoxShadow cyanGlow = BoxShadow(
    color: electricCyan.withOpacity(0.3),
    blurRadius: 40,
    spreadRadius: -10,
  );
  
  static BoxShadow purpleGlow = BoxShadow(
    color: neonPurple.withOpacity(0.3),
    blurRadius: 40,
    spreadRadius: -10,
  );
  
  // Theme Data
  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: deepNavy,
    primaryColor: electricCyan,
    colorScheme: const ColorScheme.dark(
      primary: electricCyan,
      secondary: neonPurple,
      surface: cardBackground,
      background: deepNavy,
    ),
    cardTheme: CardThemeData(
      color: cardBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: electricCyan,
        foregroundColor: Colors.black,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );
}
