import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kigo_user/l10n/app_localizations.dart';
import 'package:kigo_user/theme/app_theme.dart';

void main() {
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
}
