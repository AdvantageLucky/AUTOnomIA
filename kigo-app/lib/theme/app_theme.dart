import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tokens de diseño — alineados con el sistema de diseño Kigo (mismo que dashboard).
class AppTheme {
  // ── Brand ──────────────────────────────────────────────────────────────────
  static const Color primaryOrange = Color(0xFFFF542F);

  // ── Dark ───────────────────────────────────────────────────────────────────
  static const Color backgroundBlack = Color(0xFF09090D);
  static const Color surfaceDark     = Color(0xFF0F1018);
  static const Color surface2Dark    = Color(0xFF141523);
  static const Color cardDark        = Color(0xFF1A1B2E);
  static const Color borderDark      = Color(0xFF1E1F2E);

  // ── Light ──────────────────────────────────────────────────────────────────
  static const Color backgroundLight = Color(0xFFF2F1F7);
  static const Color surfaceLight    = Color(0xFFFFFFFF);
  static const Color borderLight     = Color(0xFFDDDCE8);

  // ── Text ───────────────────────────────────────────────────────────────────
  static const Color textWhite     = Color(0xFFECEAF4);
  static const Color textGrey      = Color(0xFF888AA6);
  static const Color textDimmed    = Color(0xFF5C5D77);
  static const Color textDark      = Color(0xFF0C0C14);

  // ── Semantic ───────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF2DCFA8);
  static const Color error   = Color(0xFFFF4D6A);
  static const Color brandHover    = Color(0xFFFF6B47);
  static const Color amber         = Color(0xFFFFC542);
  static const Color blue          = Color(0xFF5B8AF5);
  static const Color surface2Light = Color(0xFFEBEBF2);

  // ── Radius ─────────────────────────────────────────────────────────────────
  static const double radiusSm = 6.0;
  static const double radius   = 10.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 22.0;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryOrange,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: primaryOrange,
        secondary: primaryOrange,
        surface: surfaceLight,
        outline: borderLight,
        onSurface: textDark,
        onSurfaceVariant: Color(0xFF8A8BA8),
        error: error,
      ),
      textTheme: GoogleFonts.spaceGroteskTextTheme(ThemeData.light().textTheme).apply(
        bodyColor: textDark,
        displayColor: textDark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceLight,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: textDark),
        titleTextStyle: GoogleFonts.spaceGrotesk(
          color: textDark,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryOrange,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
          textStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: borderLight),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface2Light,
        labelStyle: const TextStyle(color: Color(0xFF8A8BA8)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(radius)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: primaryOrange, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: error),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryOrange,
      scaffoldBackgroundColor: backgroundBlack,
      colorScheme: const ColorScheme.dark(
        primary: primaryOrange,
        secondary: primaryOrange,
        surface: surfaceDark,
        surfaceContainerLow: surfaceDark,
        surfaceContainer: surface2Dark,
        surfaceContainerHigh: cardDark,
        outline: borderDark,
        onSurface: textWhite,
        onSurfaceVariant: textGrey,
        error: error,
      ),
      textTheme: GoogleFonts.spaceGroteskTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: textWhite,
        displayColor: textWhite,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundBlack,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: textWhite),
        titleTextStyle: GoogleFonts.spaceGrotesk(
          color: textWhite,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryOrange,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
          textStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: borderDark),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface2Dark,
        labelStyle: const TextStyle(color: textGrey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(radius)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: primaryOrange, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: error),
        ),
      ),
    );
  }
}
