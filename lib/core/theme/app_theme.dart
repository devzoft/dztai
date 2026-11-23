import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const darkBackground = Color(0xFF090B0A);
  static const lightBackground = Color(0xFFF5F7F5);
  static const accent = Color(0xFF10B981);
  static const surface = Color(0xFF141916);
  static const darkSurface = Color(0xFF111613);
  static const darkRaised = Color(0xFF1A211D);
  static const lightRaised = Color(0xFFFFFFFF);
  static const darkBorder = Color(0xFF29312C);
  static const lightBorder = Color(0xFFE2E9E4);
}

class AppTheme {
  static ThemeData light() => _buildTheme(Brightness.light);

  static ThemeData dark() => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: AppColors.accent,
            brightness: brightness,
          ).copyWith(
            primary: AppColors.accent,
            onPrimary: const Color(0xFF06251A),
            surface: isDark
                ? AppColors.darkBackground
                : AppColors.lightBackground,
            surfaceContainerLowest: isDark
                ? AppColors.darkBackground
                : const Color(0xFFFFFFFF),
            surfaceContainerLow: isDark
                ? AppColors.darkSurface
                : const Color(0xFFF0F4F1),
            surfaceContainer: isDark
                ? AppColors.surface
                : const Color(0xFFEBF0EC),
            surfaceContainerHigh: isDark
                ? AppColors.darkRaised
                : const Color(0xFFE5ECE7),
            surfaceContainerHighest: isDark
                ? const Color(0xFF202822)
                : const Color(0xFFDFE8E2),
            outline: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            outlineVariant: isDark
                ? const Color(0xFF202722)
                : const Color(0xFFEBF0EC),
          ),
    );
    final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: base.colorScheme.onSurface,
      displayColor: base.colorScheme.onSurface,
    );
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: base.colorScheme.outline),
    );

    return base.copyWith(
      scaffoldBackgroundColor: base.colorScheme.surface,
      textTheme: textTheme.copyWith(
        headlineLarge: textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -1.2,
        ),
        headlineMedium: textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: base.colorScheme.surface,
        foregroundColor: base.colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: isDark ? AppColors.darkSurface : AppColors.lightRaised,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: base.colorScheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkSurface : AppColors.lightRaised,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: base.colorScheme.onSurfaceVariant,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: const Color(0xFF06251A),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          side: BorderSide(color: base.colorScheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: base.colorScheme.outlineVariant),
        labelStyle: textTheme.labelMedium,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightRaised,
        indicatorColor: AppColors.accent.withValues(alpha: 0.16),
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: base.colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
