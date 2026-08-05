import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('es'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'es': {
      // Dashboard
      'dashboard_title': 'PANEL KIGO',
      'welcome': 'Bienvenido, Iván',
      'user_status': 'Residencial Kigo / Usuario Activo',
      'quick_actions': 'Acciones Rápidas',
      'create_invitation': 'Crear Invitación',
      'my_invitations': 'Mis Invitaciones',
      'accesses': 'Accesos',
      'my_pin': 'Mi PIN',

      // Generar Invitación
      'generate_qr_title': 'GENERAR INVITACIÓN',
      'visitor_name': 'Nombre del Visitante',
      'company': 'Empresa / Procedencia',
      'visit_reason': 'Motivo de Visita',
      'entry_time': 'Hora de Entrada',
      'duration': 'Duración (Horas)',
      'generate_button': 'GENERAR CÓDIGO QR',

      // Mis Invitaciones
      'my_invitations_title': 'MIS INVITACIONES',
      'no_active_invitations': 'No tienes invitaciones activas.',
    },
    'en': {
      // Dashboard
      'dashboard_title': 'KIGO DASHBOARD',
      'welcome': 'Welcome, Iván',
      'user_status': 'Kigo Residential / Active User',
      'quick_actions': 'Quick Actions',
      'create_invitation': 'Create Invitation',
      'my_invitations': 'My Invitations',
      'accesses': 'Access',
      'my_pin': 'My PIN',

      // Generar Invitación
      'generate_qr_title': 'GENERATE INVITATION',
      'visitor_name': 'Visitor Name',
      'company': 'Company / Origin',
      'visit_reason': 'Reason for Visit',
      'entry_time': 'Entry Time',
      'duration': 'Duration (Hours)',
      'generate_button': 'GENERATE QR CODE',

      // Mis Invitaciones
      'my_invitations_title': 'MY INVITATIONS',
      'no_active_invitations': 'You have no active invitations.',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['es', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}