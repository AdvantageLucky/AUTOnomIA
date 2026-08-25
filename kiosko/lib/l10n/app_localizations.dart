import 'package:flutter/material.dart';

/// Traducciones estáticas de la app kiosko — mismo patrón que
/// kigo-app/lib/l10n/app_localizations.dart (Map ES/EN + delegate simple,
/// sin generación de código ni paquete de i18n). El backend ya manda
/// KioskoConfig.idioma y main.dart ya arma el Locale con eso — antes de
/// esto no había ningún string real detrás, cambiar el idioma no traducía
/// nada.
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
      // Registro táctil (peatonal + vehicular, mensajes de voz)
      'welcome_message': 'Hola, soy Kigo. Te ayudaré con tu registro. Comencemos.',
      'listening_message': 'Te escucho, puedes hablar ahora.',
      'ine_invalid_message': 'No reconocimos el documento. Acércalo a la cámara y vuelve a intentar.',
      'face_not_detected_message': 'No detectamos tu rostro. Asegúrate de tener buena luz y vuelve a intentar.',
      'registration_complete_message': 'Registro completado exitosamente.',
      'kigo_label': 'Kigo',
      'footer_text': 'POWERED BY KIGO · FEPRO 2026',
      'retry_button_text': 'Reintentar',
      'back_button_text': 'Regresar',
      'continue_button_text': 'Confirmar',
      'continue_press_text': 'Presionar para continuar',
      'ine_invalid_error_title': 'Identificación inválida',
      'face_not_detected_error_title': 'Rostro no detectado',
      'ine_invalid_error_content': 'No reconocimos el documento. Acércalo a la cámara y vuelve a intentar.',
      'face_not_detected_error_content': 'No detectamos tu rostro. Asegúrate de tener buena luz y vuelve a intentar.',
      'instruction_area_capture': 'Área de captura',
      'instruction_camera_preview': 'Vista previa de la cámara',
      'no_leida': 'No leída',
      'ine_detected_title': 'Identificación detectada, puedes continuar',
      'ine_title': 'Identificación',
      'ine_subtitle': 'Mantén el documento centrado frente a la cámara',
      'photo_evidence_title': 'Evidencia fotográfica',
      'photo_evidence_subtitle': 'Coloca tu rostro frente a la cámara',
      'voice_instruction_ine': 'Muestra tu identificación frente a la cámara sin moverla.',
      'voice_instruction_face': 'Mira de frente a la cámara para tomar tu fotografía.',
      'welcome_vehicular_message': 'Hola, soy Kigo. Registra tu entrada sin bajar del vehículo. Comencemos.',
      'capturar_ine_button': 'Capturar INE',
      'reconocimiento_facial_button': 'Reconocimiento Facial',

      // Activación del dispositivo (RFC 8628)
      'activando_dispositivo': 'Activando dispositivo...',
      'activacion_completada': 'Activación completada...',
      'activar_dispositivo_title': 'Activar dispositivo',
      'activar_dispositivo_subtitle': 'Escanea el código QR o ingresa el código en el panel de administración.',
      'expira_en_prefix': 'Expira en',
      'o_separador': 'O',
      'codigo_label': 'Código',
      'codigo_expirado_title': 'El código ha expirado',
      'codigo_expirado_subtitle': 'Solicita uno nuevo para continuar.',
      'solicitar_nuevo_codigo_button': 'Solicitar nuevo código',
      'error_desconocido': 'Error desconocido',

      // Resumen de solicitud y espera de aprobación
      'faltan_datos_registro': 'Faltan datos del registro. Regresa e intenta de nuevo.',
      'no_se_pudo_registrar_prefix': 'No se pudo registrar tu acceso. Intenta de nuevo.\n\nDetalle:',
      'revision_manual_dialog_title': 'Pasó a revisión manual',
      'revision_manual_dialog_content': 'La solicitud pasó el tiempo límite de respuesta, tu solicitud pasó a '
          'revisión manual. Un vigilante te atenderá en breve.',
      'entendido_button': 'Entendido',
      'enviando_solicitud': 'Enviando tu solicitud…',
      'esperando_aprobacion': 'Esperando aprobación…',
      'esperando_aprobacion_subtitle': 'Un residente o administrador debe autorizar tu acceso',
      'en_revision_manual_title': 'En revisión manual',
      'en_revision_manual_subtitle': 'Un vigilante revisará tu acceso en breve',
      'acceso_aprobado': '¡Acceso aprobado!',
      'acceso_no_autorizado': 'Acceso no autorizado',
      'visitante_label': 'Visitante',
      'hora_solicitud_label': 'Hora de solicitud',
      'casa_destino_label': 'Casa destino',
      'no_especificado': 'No especificado',
      'placa_label': 'Placa',
    },
    'en': {
      'welcome_message': "Hi, I'm Kigo. I'll help you register. Let's start.",
      'listening_message': "I'm listening, you can speak now.",
      'ine_invalid_message': "We didn't recognize the document. Bring it closer to the camera and try again.",
      'face_not_detected_message': "We didn't detect your face. Make sure you have good lighting and try again.",
      'registration_complete_message': 'Registration completed successfully.',
      'kigo_label': 'Kigo',
      'footer_text': 'POWERED BY KIGO · FEPRO 2026',
      'retry_button_text': 'Retry',
      'back_button_text': 'Back',
      'continue_button_text': 'Confirm',
      'continue_press_text': 'Press to continue',
      'ine_invalid_error_title': 'Invalid ID',
      'face_not_detected_error_title': 'Face not detected',
      'ine_invalid_error_content': "We didn't recognize the document. Bring it closer to the camera and try again.",
      'face_not_detected_error_content': "We didn't detect your face. Make sure you have good lighting and try again.",
      'instruction_area_capture': 'Capture area',
      'instruction_camera_preview': 'Camera preview',
      'no_leida': 'Not read',
      'ine_detected_title': 'ID detected, you can continue',
      'ine_title': 'ID',
      'ine_subtitle': 'Keep the document centered in front of the camera',
      'photo_evidence_title': 'Photo evidence',
      'photo_evidence_subtitle': 'Position your face in front of the camera',
      'voice_instruction_ine': 'Show your ID to the camera without moving it.',
      'voice_instruction_face': 'Look straight at the camera to take your photo.',
      'welcome_vehicular_message': "Hi, I'm Kigo. Register your entry without leaving your vehicle. Let's start.",
      'capturar_ine_button': 'Capture ID',
      'reconocimiento_facial_button': 'Face Recognition',

      // Activación del dispositivo (RFC 8628)
      'activando_dispositivo': 'Activating device...',
      'activacion_completada': 'Activation complete...',
      'activar_dispositivo_title': 'Activate device',
      'activar_dispositivo_subtitle': 'Scan the QR code or enter the code in the admin panel.',
      'expira_en_prefix': 'Expires in',
      'o_separador': 'OR',
      'codigo_label': 'Code',
      'codigo_expirado_title': 'The code has expired',
      'codigo_expirado_subtitle': 'Request a new one to continue.',
      'solicitar_nuevo_codigo_button': 'Request new code',
      'error_desconocido': 'Unknown error',

      // Resumen de solicitud y espera de aprobación
      'faltan_datos_registro': 'Missing registration data. Go back and try again.',
      'no_se_pudo_registrar_prefix': "We couldn't register your access. Try again.\n\nDetail:",
      'revision_manual_dialog_title': 'Moved to manual review',
      'revision_manual_dialog_content': 'Your request exceeded the response time limit and was moved to '
          'manual review. A guard will attend to you shortly.',
      'entendido_button': 'Got it',
      'enviando_solicitud': 'Sending your request…',
      'esperando_aprobacion': 'Waiting for approval…',
      'esperando_aprobacion_subtitle': 'A resident or administrator must authorize your access',
      'en_revision_manual_title': 'Under manual review',
      'en_revision_manual_subtitle': 'A guard will review your access shortly',
      'acceso_aprobado': 'Access approved!',
      'acceso_no_autorizado': 'Access not authorized',
      'visitante_label': 'Visitor',
      'hora_solicitud_label': 'Request time',
      'casa_destino_label': 'Destination',
      'no_especificado': 'Not specified',
      'placa_label': 'License plate',
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
