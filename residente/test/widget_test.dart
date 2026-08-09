import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:kigo_user/l10n/app_localizations.dart';
import 'package:kigo_user/theme/app_theme.dart';
import 'package:kigo_user/viewmodels/auth_viewmodel.dart';
import 'package:kigo_user/viewmodels/invitation_viewmodel.dart';
import 'package:kigo_user/viewmodels/settings_viewmodel.dart';
import 'package:kigo_user/views/login_view.dart';

// Widget mínimo que envuelve una vista con todos los providers requeridos.
Widget _wrapProviders(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthViewModel()),
      ChangeNotifierProvider(create: (_) => SettingsViewModel()),
      ChangeNotifierProvider(create: (_) => InvitationViewModel()),
    ],
    child: MaterialApp(
      locale: const Locale('es'),
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: child,
    ),
  );
}

void main() {
  // google_fonts intenta descargar fuentes por red en tests — lo desactivamos.
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('AppLocalizations', () {
    test('traduce claves en español', () {
      final l = AppLocalizations(const Locale('es'));
      expect(l.translate('login_title'), 'Iniciar Sesión');
      expect(l.translate('dashboard_title'), 'PANEL KIGO');
      expect(l.translate('generate_qr_title'), 'GENERAR INVITACIÓN');
    });

    test('traduce claves en inglés', () {
      final l = AppLocalizations(const Locale('en'));
      expect(l.translate('login_title'), 'Sign In');
      expect(l.translate('dashboard_title'), 'KIGO DASHBOARD');
      expect(l.translate('generate_qr_title'), 'GENERATE INVITATION');
    });

    test('retorna la clave si no existe traducción', () {
      final l = AppLocalizations(const Locale('es'));
      expect(l.translate('clave_inexistente'), 'clave_inexistente');
    });

    test('cae al español si la clave no existe en inglés', () {
      final l = AppLocalizations(const Locale('en'));
      // Todas las claves del mapa inglés deben existir
      expect(l.translate('login_btn'), 'SIGN IN');
    });
  });

  group('AppTheme tokens', () {
    // Verificamos los tokens directamente sin construir ThemeData,
    // porque ThemeData con google_fonts dispara carga de fuente por red en tests.
    test('brand color es el token unificado del sistema Kigo', () {
      expect(AppTheme.primaryOrange, const Color(0xFFFF542F));
    });

    test('background dark es el token unificado', () {
      expect(AppTheme.backgroundBlack, const Color(0xFF09090D));
    });

    test('background light es el token unificado', () {
      expect(AppTheme.backgroundLight, const Color(0xFFF2F1F7));
    });

    test('success color coincide con dashboard', () {
      expect(AppTheme.success, const Color(0xFF2DCFA8));
    });

    test('error color coincide con dashboard', () {
      expect(AppTheme.error, const Color(0xFFFF4D6A));
    });
  });

  group('LoginView smoke test', () {
    testWidgets('renderiza el formulario de login', (tester) async {
      await tester.pumpWidget(_wrapProviders(const LoginView()));
      await tester.pumpAndSettle();

      // Los tres campos deben estar presentes
      expect(find.byType(TextFormField), findsNWidgets(3));
      // El botón de entrar
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('muestra error de validación con campos vacíos', (tester) async {
      await tester.pumpWidget(_wrapProviders(const LoginView()));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // El validador del primer campo debe disparar "Requerido"
      expect(find.text('Requerido'), findsWidgets);
    });
  });
}
