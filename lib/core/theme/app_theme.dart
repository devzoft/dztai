import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const darkBackground = Color(0xFF090B0A);
  static const lightBackground = Color(0xFFF7F8F7);
  static const accent = Color(0xFF10B981);
  static const surface = Color(0xFF202722);
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        brightness: Brightness.light,
      ).copyWith(surface: AppColors.lightBackground),
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
    );
  }

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        brightness: Brightness.dark,
      ).copyWith(surface: AppColors.surface),
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
    );
  }
}
