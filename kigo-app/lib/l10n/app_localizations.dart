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
      'privacy_policy_draft_notice':
          'Este es un borrador informativo pendiente de revisión legal — no sustituye un aviso de privacidad formal.',
      'privacy_policy_body':
          '¿Qué datos recolectamos?\n\nTu nombre completo, tu número de teléfono (para verificarte por código SMS), tu CURP y la fotografía de tu INE cuando te registras en un centro habitacional, y una muestra biométrica de tu rostro — un vector numérico calculado a partir de tu foto, no la foto en sí — para permitirte el acceso por reconocimiento facial.\n\n¿Para qué los usamos?\n\nPara verificar tu identidad al iniciar sesión, para que el centro habitacional donde vives te reconozca como residente o valide tus invitaciones, y para que los kioskos de acceso puedan comparar tu rostro contra esa muestra biométrica al momento de entrar.\n\n¿Con quién se comparte?\n\nTus datos quedan dentro del sistema de Kigo del centro habitacional al que perteneces — no se comparten con otros centros. Si usas la opción alternativa "Verificar con Kigo", tu fotografía se envía directamente al servicio externo de Kigo Verify para ese trámite específico; en el flujo normal de reconocimiento facial, tu fotografía nunca sale de tu dispositivo, solo el vector numérico calculado localmente.\n\nTus compañeros de casa solo ven tu nombre y tu rol dentro de la vivienda — nunca tu teléfono, CURP ni fotografías.\n\n¿Qué puedes hacer?\n\nSi quieres consultar, corregir o eliminar tus datos, contacta al administrador de tu centro habitacional — es quien administra esta información dentro de la plataforma.',
      'edit_username_title': 'Nombre de Usuario',
      'edit_username_hint': 'Ingresa tu nombre',
      'save': 'GUARDAR',

      // Solicitudes de acceso (aprobar/rechazar)
      'pending_visits': 'Solicitudes de acceso',
      'pending_visits_title': 'SOLICITUDES DE ACCESO',
      'no_pending_visits': 'No tienes solicitudes pendientes.',
      'plate_label': 'Placa',
      'approve': 'Aceptar',
      'reject': 'Rechazar',
      'visit_approved': 'Visita aprobada',
      'visit_rejected': 'Visita rechazada',
      'visit_response_error': 'No se pudo responder la solicitud',
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
      'privacy_policy_draft_notice':
          'This is an informational draft pending legal review — it does not replace a formal privacy notice.',
      'privacy_policy_body':
          'What data do we collect?\n\nYour full name, your phone number (to verify you via SMS code), your CURP and your ID photo when you register at a residential community, and a biometric sample of your face — a numeric vector calculated from your photo, not the photo itself — to allow you facial-recognition access.\n\nWhat do we use it for?\n\nTo verify your identity when you sign in, so the community you live in recognizes you as a resident or validates your invitations, and so the access kiosks can compare your face against that biometric sample when you enter.\n\nWho do we share it with?\n\nYour data stays within the Kigo system of the community you belong to — it is not shared with other communities. If you use the alternative "Verify with Kigo" option, your photo is sent directly to the external Kigo Verify service for that specific process; in the normal facial-recognition flow, your photo never leaves your device, only the numeric vector calculated locally.\n\nYour housemates only see your name and your role in the household — never your phone, CURP, or photos.\n\nWhat can you do?\n\nIf you want to review, correct, or delete your data, contact your community\'s administrator — they manage this information within the platform.',
      'edit_username_title': 'Username',
      'edit_username_hint': 'Enter your name',
      'save': 'SAVE',

      // Access requests (approve/reject)
      'pending_visits': 'Access requests',
      'pending_visits_title': 'ACCESS REQUESTS',
      'no_pending_visits': 'You have no pending requests.',
      'plate_label': 'Plate',
      'approve': 'Approve',
      'reject': 'Reject',
      'visit_approved': 'Visit approved',
      'visit_rejected': 'Visit rejected',
      'visit_response_error': 'Could not respond to the request',
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
