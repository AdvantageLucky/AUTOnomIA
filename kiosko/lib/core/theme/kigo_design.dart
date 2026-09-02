import 'package:flutter/material.dart';

/// Tema que el dashboard tiene configurado para este kiosko, en una variable
/// suelta además de en el `ThemeData`.
///
/// `PantallaError` se dibuja por debajo del `MaterialApp` —un fallo de build
/// puede reventar antes de que exista— y ahí `Theme.of` no sirve. `main.dart`
/// deja aquí el valor al construir la app. Es un `bool` a secas y no un
/// `ValueNotifier` a propósito: escribirlo a media construcción no debe marcar
/// nada sucio ni disparar un "Build scheduled during frame".
bool kigoTemaClaroActivo = false;

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
  static const textSecondaryLight  = Color(0xFF6B6C82);
  static const textTertiaryLight   = Color(0xFF8A8BA8);

  // ── Semantic ───────────────────────────────────────────────────────────────
  static const success = Color(0xFF2DCFA8);
  static const error   = Color(0xFFFF4D6A);
  static const amber   = Color(0xFFFFC542);
  static const blue    = Color(0xFF5B8AF5);

  // ── Asistente ──────────────────────────────────────────────────────────────
  // Un kiosko se opera de pie y a brazo extendido, sin la precision de un
  // telefono en la mano: 44 (el minimo tactil de movil, que es lo que tenia
  // antes) queda tapado por la yema del dedo y no se ve si respondio.
  static const ladoAsistente = 76.0;

  // ── Radius ─────────────────────────────────────────────────────────────────
  static const radius   = 10.0;
  static const radiusSm = 6.0;
  static const radiusLg = 16.0;
  static const radiusXl = 22.0;

  /// Fuente monoespaciada para datos "literales" (placa, CURP) — mismo
  /// tratamiento que ya usa el dashboard admin (JetBrains Mono).
  static TextStyle mono(TextStyle base) => base.copyWith(fontFamily: 'JetBrains Mono');

  /// Unbounded para titulares/números grandes: trazo grueso y geométrico
  /// tipo señalética, no la típica display de dashboard. Manrope para el
  /// resto del cuerpo — legible a distancia táctil, sin ser Inter.
  static TextTheme _construirTextTheme(TextTheme base, Color bodyColor, Color displayColor) {
    return base
        .copyWith(
          displayLarge: base.displayLarge?.copyWith(fontFamily: 'Unbounded'),
          displayMedium: base.displayMedium?.copyWith(fontFamily: 'Unbounded'),
          displaySmall: base.displaySmall?.copyWith(fontFamily: 'Unbounded'),
          headlineLarge: base.headlineLarge?.copyWith(fontFamily: 'Unbounded'),
          headlineMedium: base.headlineMedium?.copyWith(fontFamily: 'Unbounded'),
          headlineSmall: base.headlineSmall?.copyWith(fontFamily: 'Unbounded'),
          titleLarge: base.titleLarge?.copyWith(fontFamily: 'Unbounded'),
          titleMedium: base.titleMedium?.copyWith(fontFamily: 'Manrope'),
          titleSmall: base.titleSmall?.copyWith(fontFamily: 'Manrope'),
          bodyLarge: base.bodyLarge?.copyWith(fontFamily: 'Manrope'),
          bodyMedium: base.bodyMedium?.copyWith(fontFamily: 'Manrope'),
          bodySmall: base.bodySmall?.copyWith(fontFamily: 'Manrope'),
          labelLarge: base.labelLarge?.copyWith(fontFamily: 'Manrope'),
          labelMedium: base.labelMedium?.copyWith(fontFamily: 'Manrope'),
          labelSmall: base.labelSmall?.copyWith(fontFamily: 'Manrope'),
        )
        .apply(bodyColor: bodyColor, displayColor: displayColor);
  }

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
        textTheme: _construirTextTheme(ThemeData.dark().textTheme, textPrimary, textPrimary),
        appBarTheme: const AppBarTheme(
          backgroundColor: bgDark,
          elevation: 0,
          centerTitle: true,
          foregroundColor: textPrimary,
        ),
        cardTheme: CardThemeData(
          color: surfaceCard,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLg)),
        ),
        dividerTheme: const DividerThemeData(color: border),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: brand,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
            textStyle: const TextStyle(fontFamily: 'Unbounded', fontWeight: FontWeight.w600, fontSize: 15),
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
        textTheme: _construirTextTheme(ThemeData.light().textTheme, textDark, textDark),
        appBarTheme: const AppBarTheme(
          backgroundColor: surfaceLight,
          elevation: 0,
          centerTitle: true,
          foregroundColor: textDark,
        ),
        cardTheme: CardThemeData(
          color: surfaceLight,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLg)),
        ),
        dividerTheme: const DividerThemeData(color: borderLight),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: brand,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
            textStyle: const TextStyle(fontFamily: 'Unbounded', fontWeight: FontWeight.w600, fontSize: 15),
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

/// Tokens resueltos contra el tema activo (claro/oscuro) del kiosko.
///
/// El modo se configura desde el dashboard (`Modo del kiosko`) y llega a la
/// app como `KioskoColorTema`, que `main.dart` traduce a `KigoDesign.lightTheme`
/// o `darkTheme`. Las vistas no deben usar los tokens crudos `bgDark`,
/// `surface2`, `textPrimary`… porque quedan fijos en oscuro: se leen desde aquí
/// para que cambien con el tema.
extension KigoTema on BuildContext {
  /// `true` cuando el kiosko está configurado en modo claro.
  bool get esTemaClaro => Theme.of(this).brightness == Brightness.light;

  // ── Fondos ─────────────────────────────────────────────────────────────────
  Color get kBg          => esTemaClaro ? KigoDesign.bgLight       : KigoDesign.bgDark;
  Color get kSurface1    => esTemaClaro ? KigoDesign.surfaceLight  : KigoDesign.surface1;
  Color get kSurface2    => esTemaClaro ? KigoDesign.surface2Light : KigoDesign.surface2;
  Color get kSurfaceCard => esTemaClaro ? KigoDesign.surfaceLight  : KigoDesign.surfaceCard;
  Color get kBorder      => esTemaClaro ? KigoDesign.borderLight   : KigoDesign.border;

  // ── Texto ──────────────────────────────────────────────────────────────────
  Color get kTextPrimary   => esTemaClaro ? KigoDesign.textDark           : KigoDesign.textPrimary;
  Color get kTextSecondary => esTemaClaro ? KigoDesign.textSecondaryLight : KigoDesign.textSecondary;
  Color get kTextTertiary  => esTemaClaro ? KigoDesign.textTertiaryLight  : KigoDesign.textTertiary;

  /// Texto/iconos que van encima de un relleno de marca (naranja) o de un
  /// color semántico saturado: siempre blanco, en los dos temas.
  Color get kOnBrand => Colors.white;

  /// Velo de las capas que oscurecen el contenido (barreras de diálogo,
  /// overlays sobre la cámara). En claro se atenúa para no ennegrecer la vista.
  Color kVelo(double alpha) => esTemaClaro
      ? Colors.black.withValues(alpha: alpha * 0.55)
      : Colors.black.withValues(alpha: alpha);

  /// Relleno tenue de marca para chips, badges e iconos suaves.
  Color kBrandSuave(double alpha) =>
      KigoDesign.brand.withValues(alpha: esTemaClaro ? alpha * 0.7 : alpha);

  /// Hueco del ícono en las tarjetas del flujo de registro. En oscuro es el
  /// marrón caliente de siempre; en claro, un naranja muy diluido — un marrón
  /// sólido sobre tarjeta blanca se ve como una mancha.
  Color get kChipMarca => esTemaClaro
      ? KigoDesign.brand.withValues(alpha: 0.12)
      : const Color(0xFF3A2420);

  /// Tecla presionada de los teclados numéricos (PIN de residente y de
  /// operador), en su variante secundaria (borrar).
  Color get kTeclaPresionada => esTemaClaro
      ? KigoDesign.brand.withValues(alpha: 0.16)
      : const Color(0xFF3D2020);
}
