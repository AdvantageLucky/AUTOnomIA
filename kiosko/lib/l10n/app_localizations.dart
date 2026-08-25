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
