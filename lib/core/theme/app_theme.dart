import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppThemePreset {
  candlelight,
  midnight,
  terracotta,
  sage;

  String get displayName {
    switch (this) {
      case AppThemePreset.candlelight:
        return 'Candlelight Warmth';
      case AppThemePreset.midnight:
        return 'Midnight Obsidian';
      case AppThemePreset.terracotta:
        return 'Terracotta & Linen';
      case AppThemePreset.sage:
        return 'Eucalyptus Sage';
    }
  }

  static AppThemePreset fromString(String val) {
    for (final preset in AppThemePreset.values) {
      if (preset.name == val) return preset;
    }
    return AppThemePreset.candlelight;
  }
}

class AppPalette {
  final Color background;
  final Color surface;
  final Color cardBackground;
  final Color primary;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Brightness brightness;

  const AppPalette({
    required this.background,
    required this.surface,
    required this.cardBackground,
    required this.primary,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.brightness,
  });

  static const candlelight = AppPalette(
    background: Color(0xFFF9F6F0),
    surface: Color(0xFFF2ECE1),
    cardBackground: Color(0xFFFFFFFF),
    primary: Color(0xFFC05621),
    textPrimary: Color(0xFF28211D),
    textSecondary: Color(0xFF6B5E55),
    border: Color(0xFFE5DDD0),
    brightness: Brightness.light,
  );

  static const midnight = AppPalette(
    background: Color(0xFF111113),
    surface: Color(0xFF1A1A1E),
    cardBackground: Color(0xFF222228),
    primary: Color(0xFFE5A638),
    textPrimary: Color(0xFFF3F3F5),
    textSecondary: Color(0xFFA5A5B0),
    border: Color(0xFF2D2D35),
    brightness: Brightness.dark,
  );

  static const terracotta = AppPalette(
    background: Color(0xFFF4ECE6),
    surface: Color(0xFFEADFD7),
    cardBackground: Color(0xFFFFFDFB),
    primary: Color(0xFFA84323),
    textPrimary: Color(0xFF2A1C16),
    textSecondary: Color(0xFF6E564D),
    border: Color(0xFFDECFCE),
    brightness: Brightness.light,
  );

  static const sage = AppPalette(
    background: Color(0xFFEBF1ED),
    surface: Color(0xFFDEE8E1),
    cardBackground: Color(0xFFFBFCFA),
    primary: Color(0xFF295A43),
    textPrimary: Color(0xFF16251D),
    textSecondary: Color(0xFF536A5D),
    border: Color(0xFFCFDCD2),
    brightness: Brightness.light,
  );

  static AppPalette forPreset(AppThemePreset preset) {
    switch (preset) {
      case AppThemePreset.candlelight:
        return candlelight;
      case AppThemePreset.midnight:
        return midnight;
      case AppThemePreset.terracotta:
        return terracotta;
      case AppThemePreset.sage:
        return sage;
    }
  }
}

class AppTheme {
  static ThemeData buildTheme(AppThemePreset preset) {
    final palette = AppPalette.forPreset(preset);
    final isDark = palette.brightness == Brightness.dark;

    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme(
      isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: palette.brightness,
      scaffoldBackgroundColor: palette.background,
      colorScheme: ColorScheme(
        brightness: palette.brightness,
        primary: palette.primary,
        onPrimary: Colors.white,
        secondary: palette.primary,
        onSecondary: Colors.white,
        surface: palette.surface,
        onSurface: palette.textPrimary,
        error: Colors.redAccent,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        foregroundColor: palette.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.newsreader(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: palette.textPrimary,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: palette.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: palette.border, width: 1.2),
        ),
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.newsreader(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: palette.textPrimary,
          height: 1.25,
        ),
        displayMedium: GoogleFonts.newsreader(
          fontSize: 26,
          fontWeight: FontWeight.w600,
          color: palette.textPrimary,
          height: 1.3,
        ),
        headlineMedium: GoogleFonts.newsreader(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: palette.textPrimary,
          height: 1.35,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: palette.textPrimary,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: palette.textPrimary,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          color: palette.textPrimary,
          height: 1.45,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: palette.textSecondary,
          height: 1.4,
        ),
        bodySmall: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          color: palette.textSecondary,
        ),
      ),
    );
  }
}
