import 'package:flutter/material.dart';

/// Centralized color palette for GreenInvest
class AppColors {
  AppColors._();

  // Primary eco-green accent
  static const Color primary = Color(0xFF1DB954);
  static const Color primaryLight = Color(0xFF4ECB71);
  static const Color primaryDark = Color(0xFF148F3F);

  // Light theme
  static const Color lightBackground = Color(0xFFF5F7FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF1A1A2E);
  static const Color lightTextSecondary = Color(0xFF6B7280);

  // Dark theme
  static const Color darkBackground = Color(0xFF0D1117);
  static const Color darkSurface = Color(0xFF161B22);
  static const Color darkCard = Color(0xFF1C2333);
  static const Color darkTextPrimary = Color(0xFFE6EDF3);
  static const Color darkTextSecondary = Color(0xFF8B949E);

  // Semantic
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // ESG Badge Colors
  static const Color esgExcellent = Color(0xFF059669); // AAA, AA
  static const Color esgGood = Color(0xFF22C55E);      // A
  static const Color esgAverage = Color(0xFFF59E0B);   // BBB
  static const Color esgBelowAvg = Color(0xFFF97316);  // BB
  static const Color esgPoor = Color(0xFFEF4444);      // B, CCC

  // Chart Colors
  static const List<Color> chartPalette = [
    Color(0xFF1DB954),
    Color(0xFF3B82F6),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFF14B8A6),
    Color(0xFFF97316),
  ];
}
