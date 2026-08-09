import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tokens de diseño unificados — mapean 1:1 con las CSS vars del dashboard.
abstract final class KigoDesign {
  // ── Brand ──────────────────────────────────────────────────────────────────
  static const brand      = Color(0xFFFF542F);
  static const brandHover = Color(0xFFFF6B47);

  // ── Dark backgrounds ───────────────────────────────────────────────────────
  static const bgDark      = Color(0xFF09090D);
  static const surface1    = Color(0xFF0F1018);
  static const surface2    = Color(0xFF141523);
  static const surfaceCard = Color(0xFF1A1B2E);
  static const border      = Color(0xFF1E1F2E);

  // ── Light backgrounds ──────────────────────────────────────────────────────
  static const bgLight       = Color(0xFFF2F1F7);
  static const surfaceLight  = Color(0xFFFFFFFF);
  static const surface2Light = Color(0xFFEBEBF2);
  static const borderLight   = Color(0xFFDDDCE8);

  // ── Text (dark) ────────────────────────────────────────────────────────────
  static const textPrimary   = Color(0xFFECEAF4);
  static const textSecondary = Color(0xFF888AA6);
  static const textTertiary  = Color(0xFF5C5D77);

  // ── Text (light) ───────────────────────────────────────────────────────────
  static const textDark            = Color(0xFF0C0C14);
  static const textSecondaryLight  = Color(0xFF8A8BA8);

  // ── Semantic ───────────────────────────────────────────────────────────────
  static const success = Color(0xFF2DCFA8);
  static const error   = Color(0xFFFF4D6A);
  static const amber   = Color(0xFFFFC542);
  static const blue    = Color(0xFF5B8AF5);

  // ── Radius ─────────────────────────────────────────────────────────────────
  static const radius   = 10.0;
  static const radiusSm = 6.0;
  static const radiusLg = 16.0;
  static const radiusXl = 22.0;

  // ── Themes ─────────────────────────────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bgDark,
        primaryColor: brand,
        colorScheme: const ColorScheme.dark(
          primary: brand,
          secondary: brand,
          surface: surface1,
          surfaceContainerLow: surface1,
          surfaceContainer: surface2,
          surfaceContainerHigh: surfaceCard,
          outline: border,
          onSurface: textPrimary,
          onSurfaceVariant: textSecondary,
          error: error,
        ),
        textTheme: GoogleFonts.spaceGroteskTextTheme(ThemeData.dark().textTheme).apply(
          bodyColor: textPrimary,
          displayColor: textPrimary,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: bgDark,
          elevation: 0,
          centerTitle: true,
          foregroundColor: textPrimary,
        ),
        cardTheme: const CardThemeData(
          color: surfaceCard,
          elevation: 0,
          margin: EdgeInsets.zero,
        ),
        dividerTheme: const DividerThemeData(color: border),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: brand,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
            textStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface2,
          labelStyle: TextStyle(color: textSecondary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: const BorderSide(color: border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: const BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: const BorderSide(color: brand, width: 1.5),
          ),
        ),
      );

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: bgLight,
        primaryColor: brand,
        colorScheme: const ColorScheme.light(
          primary: brand,
          secondary: brand,
          surface: surfaceLight,
          outline: borderLight,
          onSurface: textDark,
          onSurfaceVariant: textSecondaryLight,
          error: error,
        ),
        textTheme: GoogleFonts.spaceGroteskTextTheme(ThemeData.light().textTheme).apply(
          bodyColor: textDark,
          displayColor: textDark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: surfaceLight,
          elevation: 0,
          centerTitle: true,
          foregroundColor: textDark,
        ),
        cardTheme: const CardThemeData(
          color: surfaceLight,
          elevation: 0,
          margin: EdgeInsets.zero,
        ),
        dividerTheme: const DividerThemeData(color: borderLight),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: brand,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
            textStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface2Light,
          labelStyle: TextStyle(color: textSecondaryLight),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: const BorderSide(color: borderLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: const BorderSide(color: borderLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: const BorderSide(color: brand, width: 1.5),
          ),
        ),
      );
}
