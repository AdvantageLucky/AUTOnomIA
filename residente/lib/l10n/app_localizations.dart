import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('es'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// Shorthand: AppLocalizations.t(context, 'key')
  static String t(BuildContext context, String key) => of(context).translate(key);

  static final Map<String, Map<String, String>> _localizedValues = {
    'es': {
      // Dashboard
      'dashboard_title': 'PANEL KIGO',
      'welcome': 'Bienvenido',
      'user_status_default': 'Residencial Kigo / Usuario Activo',
      'quick_actions': 'Acciones Rápidas',
      'create_invitation': 'Crear Invitación',
      'my_invitations': 'Mis Invitaciones',
      'logout_tooltip': 'Cerrar sesión',

      // Login
      'login_title': 'Iniciar Sesión',
      'login_subtitle': 'Usa las credenciales que te asignó tu administrador',
      'login_codigo_instalacion': 'Código de la instalación',
      'login_house': 'Casa / Departamento',
      'login_pin': 'PIN (4–6 dígitos)',
      'login_btn': 'ENTRAR',
      'login_register': '¿Aún no estás registrado? Solicitar acceso',
      'required_field': 'Requerido',
      'invalid_number': 'Debe ser un número',
      'pin_length_error': 'El PIN debe tener 4–6 dígitos',

      // Invitaciones (lista)
      'my_invitations_title': 'MIS INVITACIONES',
      'no_active_invitations': 'No tienes invitaciones activas.',
      'refresh_tooltip': 'Actualizar',
      'inv_personal_label': 'Invitación personal',
      'inv_grupal_label': 'Invitación grupal',
      'close': 'Cerrar',
      'cancel': 'Cancelar',
      'revoke': 'Revocar',
      'revoke_title': 'Revocar invitación',
      'revoke_body': 'La invitación quedará inválida. ¿Continuar?',
      'inv_revoked': 'Invitación revocada',
      'revoke_error': 'Error al revocar',
      'retry': 'Reintentar',
      'qr_unavailable': 'QR no disponible.\nCrea una nueva invitación para obtener el código.',
      'inv_type_personal': 'Personal',
      'inv_type_grupal': 'Grupal',
      'inv_expires_prefix': 'vence',
      'inv_max_prefix': 'máx.',
      'inv_use_singular': 'uso',
      'inv_use_plural': 'usos',
      'see_qr': 'Ver QR',

      // Generar invitación
      'generate_qr_title': 'GENERAR INVITACIÓN',
      'visitor_name': 'Nombre del visitante o grupo',
      'inv_type_label': 'Tipo de invitación',
      'inv_personal_option': 'Personal (una persona)',
      'inv_grupal_option': 'Grupal (varias personas)',
      'max_uses_label': 'Límite de usos (vacío = sin límite)',
      'expires_label': 'Fecha de expiración',
      'generate_button': 'GENERAR CÓDIGO QR',
      'inv_created_title': '¡Invitación creada!',
      'share_btn': 'COMPARTIR (WhatsApp / etc.)',
      'view_invitations_btn': 'VER MIS INVITACIONES',
      'create_another': 'Crear otra',
      'no_destino_error': 'No se encontró el destino de tu casa. Cierra sesión e ingresa de nuevo.',
      'create_error': 'No se pudo crear la invitación',

      // Registro
      'registro_title': 'Registro de residente',
      'step_centro': 'Centro',
      'step_datos': 'Datos',
      'step_pin': 'PIN',
      'step_cara': 'Cara',
      'step_confirm': 'Confirmar',
      'building_question': '¿A qué instalación perteneces?',
      'building_subtitle': 'Ingresa el código que te compartió tu administrador.',
      'building_code_label': 'Código de la instalación',
      'building_code_hint': 'Ej: FEPRO-2026',
      'search': 'Buscar',
      'searching': 'Buscando…',
      'continue_btn': 'Continuar',
      'submit_btn': 'Solicitar acceso',
      'center_found': 'Centro encontrado',

      // Settings
      'settings_title': 'CONFIGURACIÓN',
      'section_account': 'Cuenta y Perfil',
      'section_appearance': 'Apariencia y Preferencias',
      'section_info': 'Información',
      'display_name': 'Nombre a mostrar',
      'dark_mode': 'Modo Oscuro',
      'dark_mode_on': 'Activado',
      'dark_mode_off': 'Desactivado',
      'language': 'Idioma',
      'app_version': 'Versión de App',
      'privacy_policy': 'Políticas de Privacidad',
      'edit_username_title': 'Nombre de Usuario',
      'edit_username_hint': 'Ingresa tu nombre',
      'save': 'GUARDAR',
    },
    'en': {
      // Dashboard
      'dashboard_title': 'KIGO DASHBOARD',
      'welcome': 'Welcome',
      'user_status_default': 'Kigo Residential / Active User',
      'quick_actions': 'Quick Actions',
      'create_invitation': 'Create Invitation',
      'my_invitations': 'My Invitations',
      'logout_tooltip': 'Sign out',

      // Login
      'login_title': 'Sign In',
      'login_subtitle': 'Use the credentials assigned by your administrator',
      'login_kiosko_id': 'Kiosk ID',
      'login_house': 'House / Apartment',
      'login_pin': 'PIN (4–6 digits)',
      'login_btn': 'SIGN IN',
      'login_register': 'Not registered yet? Request access',
      'required_field': 'Required',
      'invalid_number': 'Must be a number',
      'pin_length_error': 'PIN must be 4–6 digits',

      // Invitaciones (lista)
      'my_invitations_title': 'MY INVITATIONS',
      'no_active_invitations': 'You have no active invitations.',
      'refresh_tooltip': 'Refresh',
      'inv_personal_label': 'Personal invitation',
      'inv_grupal_label': 'Group invitation',
      'close': 'Close',
      'cancel': 'Cancel',
      'revoke': 'Revoke',
      'revoke_title': 'Revoke invitation',
      'revoke_body': 'The invitation will be invalidated. Continue?',
      'inv_revoked': 'Invitation revoked',
      'revoke_error': 'Error revoking',
      'retry': 'Retry',
      'qr_unavailable': 'QR not available.\nCreate a new invitation to get the code.',
      'inv_type_personal': 'Personal',
      'inv_type_grupal': 'Group',
      'inv_expires_prefix': 'expires',
      'inv_max_prefix': 'max.',
      'inv_use_singular': 'use',
      'inv_use_plural': 'uses',
      'see_qr': 'See QR',

      // Generar invitación
      'generate_qr_title': 'GENERATE INVITATION',
      'visitor_name': 'Visitor or group name',
      'inv_type_label': 'Invitation type',
      'inv_personal_option': 'Personal (one person)',
      'inv_grupal_option': 'Group (multiple people)',
      'max_uses_label': 'Usage limit (empty = unlimited)',
      'expires_label': 'Expiration date',
      'generate_button': 'GENERATE QR CODE',
      'inv_created_title': 'Invitation created!',
      'share_btn': 'SHARE (WhatsApp / etc.)',
      'view_invitations_btn': 'VIEW MY INVITATIONS',
      'create_another': 'Create another',
      'no_destino_error': 'Your home destination was not found. Sign out and sign in again.',
      'create_error': 'Could not create invitation',

      // Registro
      'registro_title': 'Resident registration',
      'step_centro': 'Building',
      'step_datos': 'Info',
      'step_pin': 'PIN',
      'step_cara': 'Face',
      'step_confirm': 'Confirm',
      'building_question': 'Which building do you belong to?',
      'building_subtitle': 'Enter the code your administrator shared with you.',
      'building_code_label': 'Building code',
      'building_code_hint': 'e.g. FEPRO-2026',
      'search': 'Search',
      'searching': 'Searching…',
      'continue_btn': 'Continue',
      'submit_btn': 'Request access',
      'center_found': 'Building found',

      // Settings
      'settings_title': 'SETTINGS',
      'section_account': 'Account & Profile',
      'section_appearance': 'Appearance & Preferences',
      'section_info': 'Information',
      'display_name': 'Display Name',
      'dark_mode': 'Dark Mode',
      'dark_mode_on': 'Enabled',
      'dark_mode_off': 'Disabled',
      'language': 'Language',
      'app_version': 'App Version',
      'privacy_policy': 'Privacy Policy',
      'edit_username_title': 'Username',
      'edit_username_hint': 'Enter your name',
      'save': 'SAVE',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? _localizedValues['es']?[key] ?? key;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['es', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
