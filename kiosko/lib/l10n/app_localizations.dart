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
      'welcome_message': 'Hola, soy AUTOnomIA. Te ayudaré con tu registro. Comencemos.',
      'listening_message': 'Te escucho, puedes hablar ahora.',
      'asistente_presentacion_message': 'Hola, soy tu asistente. Mantén presionado el micrófono de abajo si tienes dudas.',
      'asistente_etiqueta': 'Asistente IA',
      'ine_invalid_message': 'No reconocimos el documento. Acércalo a la cámara y vuelve a intentar.',
      'face_not_detected_message': 'No detectamos tu rostro. Asegúrate de tener buena luz y vuelve a intentar.',
      'registration_complete_message': 'Registro completado exitosamente.',
      'kigo_label': 'AUTOnomIA',
      'retry_button_text': 'Reintentar',
      'back_button_text': 'Regresar',
      'continue_button_text': 'Confirmar',
      'continue_press_text': 'Presionar para continuar',
      'ine_invalid_error_title': 'Identificación inválida',
      'ine_invalid_error_content': 'No reconocimos el documento. Acércalo a la cámara y vuelve a intentar.',
      'face_not_detected_title': 'Rostro no detectado',
      'face_not_detected_content': 'No logramos detectar tu rostro claramente. Asegúrate de mirar de frente a la cámara con buena iluminación y vuelve a intentar.',
      'face_not_detected_error_title': 'Rostro no detectado',
      'face_not_detected_error_content': 'No logramos detectar tu rostro claramente. Asegúrate de mirar de frente a la cámara con buena iluminación y vuelve a intentar.',
      'ine_borrosa_message': 'La foto salió borrosa. Sostén tu identificación firme y vuelve a intentar.',
      'ine_borrosa_error_title': 'Foto borrosa',
      'ine_borrosa_error_content': 'La foto de tu identificación salió borrosa. Sostenla firme, con buena luz, y vuelve a intentar.',
      'face_borrosa_message': 'La foto salió borrosa. Mantente quieto y vuelve a intentar.',
      'face_borrosa_error_title': 'Foto borrosa',
      'face_borrosa_error_content': 'Tu foto salió borrosa. Mantente quieto frente a la cámara y vuelve a intentar.',
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
      'welcome_vehicular_message': 'Hola, soy AUTOnomIA. Registra tu acceso sin bajar del vehículo. Comencemos.',
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
      'bienvenido_al_centro_generico': 'Bienvenido al centro habitacional.',
      'sugerencia_descargar_app': 'Descarga la app AUTOnomIA para tu próxima visita: entra con QR o rostro, sin volver a registrarte.',
      'acceso_no_autorizado': 'Acceso denegado',
      'visitante_label': 'Visitante',
      'hora_solicitud_label': 'Hora de solicitud',
      'casa_destino_label': 'Casa destino',
      'no_especificado': 'No especificado',
      'placa_label': 'Placa',

      // Acceso de residente por reconocimiento facial
      'no_se_pudo_activar_camara': 'No se pudo activar la cámara',
      'mira_camara_identificarte': 'Mira a la cámara para identificarte',
      'detectando_rostro_automaticamente': 'Detectando rostro automáticamente',
      'activando_camara': 'Activando cámara...',
      'o_bien': 'O bien,',
      'acceder_por_pin': 'Acceder por PIN...',
      'self_checkin_label': 'SELF CHECK-IN',
      'aviso_privacidad_title': 'Aviso de privacidad',
      'aviso_privacidad_content': 'Su rostro se analiza en este dispositivo para generar una huella digital '
          'matemática; la imagen nunca se transmite ni se almacena. Esa huella se '
          'compara de forma segura contra los residentes registrados del edificio '
          'para verificar su identidad. Si prefiere no usar reconocimiento facial, '
          'puede ingresar con su PIN.',
      'aceptar_button': 'Aceptar',
      'residente_label': 'Residente',

      // Acceso de residente por PIN
      'ingresa_tu_numero': 'Ingresa tu número',
      'confirmar_button_caps': 'CONFIRMAR',

      // Resultado de escaneo QR (invitación)
      'verificando_invitacion': 'Verificando invitación...',
      'acceso_concedido': '¡Acceso concedido!',
      'invitado_label': 'INVITADO',
      'puedes_ingresar_evento_bienvenido': 'Puedes ingresar al evento.\nBienvenido.',
      'acceso_denegado': 'Acceso denegado',
      'invitacion_no_valida': 'La invitación no es válida',
      'volver_a_intentar': 'Volver a intentar',
      'bienvenido_a_casa': 'Bienvenido a casa',
      'verificando_tu_codigo': 'Verificando tu código...',
      'cuenta_sin_invitacion_membresia': 'Esta cuenta no tiene invitación ni membresía en este centro',
      'no_se_pudo_verificar_qr': 'No se pudo verificar el código QR',

      // Diálogo de consentimiento y términos y condiciones
      'consentimiento_datos_title': 'Consentimiento de datos',
      // Menciona la huella facial explicitamente: desde que se guarda el
      // embedding del visitante (no solo la foto) esto es un dato biometrico,
      // y un consentimiento generico de "datos sensibles" no lo cubre.
      'consentimiento_datos_content': 'Para darte acceso tomaremos tu foto y, a partir de ella, una huella facial: '
          'una serie de numeros con la que podremos reconocerte en tus proximas visitas. '
          'No se puede reconstruir tu cara a partir de ella.'
          ' \n\n'
          '¿Aceptas el uso de tus datos para este fin?',
      'terminos_y_condiciones': 'Términos y condiciones',
      'terminos_y_condiciones_content': 'Este texto es de referencia y debe sustituirse por los términos y condiciones '
          'legales definitivos antes de publicar la aplicación.\n\n'
          '1. Objeto\n'
          'Los presentes términos regulan el uso del kiosco de autoservicio y el tratamiento '
          'de los datos proporcionados por el usuario durante su registro y acceso a las '
          'instalaciones.\n\n'
          '2. Datos que recabamos\n'
          'Para el proceso de registro se podrán recabar, entre otros: nombre completo, '
          'fotografía del rostro, identificación oficial (INE u otro documento) y datos de '
          'contacto asociados a la unidad o domicilio.\n\n'
          '3. Finalidad del tratamiento\n'
          'Los datos se utilizan exclusivamente para validar la identidad del usuario, '
          'gestionar el acceso a las instalaciones y mantener un registro de seguridad de '
          'ingresos y salidas.\n\n'
          '4. Conservación y seguridad\n'
          'La información se almacena de forma segura y se conserva únicamente durante el '
          'tiempo necesario para cumplir con la finalidad descrita o lo que exija la '
          'normativa aplicable.\n\n'
          '5. Derechos del usuario\n'
          'El usuario puede solicitar en cualquier momento el acceso, rectificación o '
          'eliminación de sus datos personales a través de la administración del condominio '
          'o fraccionamiento.\n\n'
          '6. Contacto\n'
          'Para dudas relacionadas con el uso de tus datos, contacta a la administración '
          'del sitio.',
      'cerrar_button': 'Cerrar',

      // Pantalla de bienvenida
      'bienvenido_title': 'Bienvenido',
      'selecciona_como_continuar': 'SELECCIONA CÓMO QUIERES CONTINUAR',
      'bienvenido_exclamacion': '¡Bienvenido!',

      // Confirmación manual de placa
      'placa_error_incompleta': 'Escribe la placa completa (5 a 8 caracteres)',
      'confirma_tu_placa': 'Confirma tu placa',
      'escribe_tu_placa': 'Escribe tu placa',
      'corrige_caracter_no_coincide': 'Si algún carácter no coincide, corrígelo con el teclado.',
      'no_detectamos_placa_escribela': 'No pudimos detectar tu placa automáticamente. Escríbela aquí.',
      'cancelar_button': 'Cancelar',

      // Selección progresiva de destino (calle/tipo/número)
      'no_se_pudo_cargar_casas': 'No se pudo cargar la lista de casas. Verifica la conexión.',
      'en_que_calle_esta_destino': '¿En qué calle está tu destino?',
      // Generico: el dashboard ya permite 7 tipos de destino, no solo dos.
      'casa_o_edificio': '¿Qué tipo de destino?',
      'cual_es_el_numero': '¿Cuál es el número?',
      'cual_es_el_motivo': '¿Cuál es el motivo de tu visita?',
      'sin_casas_registradas': 'Todavía no hay casas registradas en este kiosko.\nAvisa a la administración.',
      'edificio_label': 'Edificio',
      'casa_label': 'Casa',
      'departamento_label': 'Departamento',
      'oficina_label': 'Oficina',
      'local_label': 'Local comercial',
      'bodega_label': 'Bodega',
      'lote_label': 'Lote',
      'otro_destino_label': 'Otro',
      'no_encuentro_mi_destino': 'No encuentro mi destino',
      'escribe_tu_destino': 'Escribe tu destino',

      // Salida de modo operador (PIN)
      'modo_operador': 'MODO OPERADOR',
      'ingresa_pin_salir_kiosko': 'Ingresa el PIN para salir del modo kiosko',
      'pin_incorrecto_intenta_de_nuevo': 'PIN incorrecto, intenta de nuevo',

      // Escáner de QR (entrada principal del kiosko)
      'codigo_detectado': 'Código detectado',
      'apunta_al_codigo_qr': 'Apunta al código QR',
      'codigo_personal_o_invitacion': 'Tu código personal o el de tu invitación',
      'no_tengo_app_o_qr': 'No tengo la app AUTOnomIA o código QR',

      // Captura de rostro con óvalo guía
      'apunta_a_tu_rostro': 'Apunta a tu rostro',
      'centra_rostro_ovalo': 'Centra tu rostro dentro del óvalo',
      'detectando_rostro_auto': 'Detección automática — centra tu rostro en el óvalo',
      'rostro_detectado_capturando': '¡Rostro detectado! No te muevas...',
      'apunta_a_tu_ine': 'Apunta a tu INE',
      'deteccion_automatica_ine': 'Detección automática — mantén la INE dentro del recuadro',
      'acerca_aleja_ine': 'Acerca o aleja la INE hasta que se vea nítida',
      'apunta_a_tu_placa': 'Apunta a tu placa',
      'deteccion_automatica_placa': 'Detección automática — mantén la placa dentro del recuadro',
      'acerca_aleja_placa': 'Acerca o aleja la placa hasta que se vea nítida',
      'no_se_detecto_placa_reintentando': 'No se detectó la placa, reintentando...',
      'usar_teclado_button': 'Usar teclado en su lugar',
    },
    'en': {
      'welcome_message': "Hi, I'm AUTOnomIA. I'll help you register. Let's start.",
      'listening_message': "I'm listening, you can speak now.",
      'asistente_presentacion_message': "Hi, I'm your assistant. Hold the microphone button below if you have questions.",
      'asistente_etiqueta': 'AI Assistant',
      'ine_invalid_message': "We didn't recognize the document. Bring it closer to the camera and try again.",
      'face_not_detected_message': "We didn't detect your face. Make sure you have good lighting and try again.",
      'registration_complete_message': 'Registration completed successfully.',
      'kigo_label': 'AUTOnomIA',
      'retry_button_text': 'Retry',
      'back_button_text': 'Back',
      'continue_button_text': 'Confirm',
      'continue_press_text': 'Press to continue',
      'ine_invalid_error_title': 'Invalid ID',
      'ine_invalid_error_content': "We didn't recognize the document. Bring it closer to the camera and try again.",
      'face_not_detected_title': 'Face not detected',
      'face_not_detected_content': "We could not detect your face clearly. Make sure you face the camera directly with good lighting and try again.",
      'face_not_detected_error_title': 'Face not detected',
      'face_not_detected_error_content': "We could not detect your face clearly. Make sure you face the camera directly with good lighting and try again.",
      'ine_borrosa_message': 'The photo came out blurry. Hold your ID steady and try again.',
      'ine_borrosa_error_title': 'Blurry photo',
      'ine_borrosa_error_content': 'The photo of your ID came out blurry. Hold it steady, with good light, and try again.',
      'face_borrosa_message': 'The photo came out blurry. Stay still and try again.',
      'face_borrosa_error_title': 'Blurry photo',
      'face_borrosa_error_content': 'Your photo came out blurry. Stay still in front of the camera and try again.',
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
      'welcome_vehicular_message': "Hi, I'm AUTOnomIA. Register your entry without leaving your vehicle. Let's start.",
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
      'bienvenido_al_centro_generico': 'Welcome to the residential complex.',
      'sugerencia_descargar_app': 'Download the AUTOnomIA app for your next visit: enter with QR or face, no need to register again.',
      'acceso_no_autorizado': 'Access denied',
      'visitante_label': 'Visitor',
      'hora_solicitud_label': 'Request time',
      'casa_destino_label': 'Destination',
      'no_especificado': 'Not specified',
      'placa_label': 'License plate',

      // Acceso de residente por reconocimiento facial
      'no_se_pudo_activar_camara': 'Could not activate the camera',
      'mira_camara_identificarte': 'Look at the camera to identify yourself',
      'detectando_rostro_automaticamente': 'Automatically detecting face',
      'activando_camara': 'Activating camera...',
      'o_bien': 'Or,',
      'acceder_por_pin': 'Access with PIN...',
      'self_checkin_label': 'SELF CHECK-IN',
      'aviso_privacidad_title': 'Privacy notice',
      'aviso_privacidad_content': 'Your face is analyzed on this device to generate a mathematical '
          'fingerprint; the image is never transmitted or stored. That fingerprint is '
          "securely compared against the building's registered residents to verify "
          'your identity. If you prefer not to use facial recognition, you can enter '
          'with your PIN.',
      'aceptar_button': 'Accept',
      'residente_label': 'Resident',

      // Acceso de residente por PIN
      'ingresa_tu_numero': 'Enter your number',
      'confirmar_button_caps': 'CONFIRM',

      // Resultado de escaneo QR (invitación)
      'verificando_invitacion': 'Verifying invitation...',
      'acceso_concedido': 'Access granted!',
      'invitado_label': 'GUEST',
      'puedes_ingresar_evento_bienvenido': 'You may enter the event.\nWelcome.',
      'acceso_denegado': 'Access denied',
      'invitacion_no_valida': 'The invitation is not valid',
      'volver_a_intentar': 'Try again',
      'bienvenido_a_casa': 'Welcome home',
      'verificando_tu_codigo': 'Verifying your code...',
      'cuenta_sin_invitacion_membresia': 'This account has no invitation or membership at this facility',
      'no_se_pudo_verificar_qr': 'Could not verify the QR code',

      // Diálogo de consentimiento y términos y condiciones
      'consentimiento_datos_title': 'Data consent',
      'consentimiento_datos_content': 'To grant you access we will take your photo and, from it, a face signature: '
          'a set of numbers that lets us recognise you on your next visits. '
          'Your face cannot be reconstructed from it.'
          ' \n\n'
          'Do you agree to the use of your data for this purpose?',
      'terminos_y_condiciones': 'Terms and conditions',
      'terminos_y_condiciones_content': 'This text is a placeholder and must be replaced with the final '
          'legal terms and conditions before publishing the app.\n\n'
          '1. Purpose\n'
          'These terms govern the use of the self-service kiosk and the handling '
          'of the data provided by the user during registration and access to the '
          'facilities.\n\n'
          '2. Data we collect\n'
          'The registration process may collect, among others: full name, '
          'facial photo, official ID (INE or other document), and contact data '
          'associated with the unit or address.\n\n'
          '3. Purpose of processing\n'
          "The data is used exclusively to validate the user's identity, "
          'manage access to the facilities, and maintain a security log of '
          'entries and exits.\n\n'
          '4. Retention and security\n'
          'Information is stored securely and kept only for the time needed '
          'to fulfill the stated purpose or as required by applicable '
          'regulations.\n\n'
          '5. User rights\n'
          'The user may request access, correction, or deletion of their '
          'personal data at any time through the condominium or development '
          'administration.\n\n'
          '6. Contact\n'
          'For questions about the use of your data, contact the site '
          'administration.',
      'cerrar_button': 'Close',

      // Pantalla de bienvenida
      'bienvenido_title': 'Welcome',
      'selecciona_como_continuar': 'CHOOSE HOW YOU WANT TO CONTINUE',
      'bienvenido_exclamacion': 'Welcome!',

      // Confirmación manual de placa
      'placa_error_incompleta': 'Type the full plate (5 to 8 characters)',
      'confirma_tu_placa': 'Confirm your plate',
      'escribe_tu_placa': 'Type your plate',
      'corrige_caracter_no_coincide': "If a character doesn't match, correct it with the keyboard.",
      'no_detectamos_placa_escribela': "We couldn't detect your plate automatically. Type it here.",
      'cancelar_button': 'Cancel',

      // Selección progresiva de destino (calle/tipo/número)
      'no_se_pudo_cargar_casas': 'Could not load the list of houses. Check your connection.',
      'en_que_calle_esta_destino': 'Which street is your destination on?',
      'casa_o_edificio': 'What kind of destination?',
      'cual_es_el_numero': 'What is the number?',
      'cual_es_el_motivo': 'What is the reason for your visit?',
      'sin_casas_registradas': 'There are no houses registered in this kiosk yet.\nLet the administration know.',
      'edificio_label': 'Building',
      'casa_label': 'House',
      'departamento_label': 'Apartment',
      'oficina_label': 'Office',
      'local_label': 'Retail unit',
      'bodega_label': 'Warehouse',
      'lote_label': 'Lot',
      'otro_destino_label': 'Other',
      'no_encuentro_mi_destino': "I can't find my destination",
      'escribe_tu_destino': 'Type your destination',

      // Salida de modo operador (PIN)
      'modo_operador': 'OPERATOR MODE',
      'ingresa_pin_salir_kiosko': 'Enter the PIN to exit kiosk mode',
      'pin_incorrecto_intenta_de_nuevo': 'Incorrect PIN, try again',

      // Escáner de QR (entrada principal del kiosko)
      'codigo_detectado': 'Code detected',
      'apunta_al_codigo_qr': 'Point at the QR code',
      'codigo_personal_o_invitacion': 'Your personal code or your invitation code',
      'no_tengo_app_o_qr': "I don't have the AUTOnomIA app or a QR code",

      // Captura de rostro con óvalo guía
      'apunta_a_tu_rostro': 'Point at your face',
      'centra_rostro_ovalo': 'Center your face inside the oval',
      'detectando_rostro_auto': 'Automatic detection — center your face inside the oval',
      'rostro_detectado_capturando': 'Face detected! Hold still...',
      'apunta_a_tu_ine': 'Point at your ID',
      'deteccion_automatica_ine': 'Automatic detection — keep the ID inside the frame',
      'acerca_aleja_ine': 'Move the ID closer or farther until it looks sharp',
      'apunta_a_tu_placa': 'Point at your plate',
      'deteccion_automatica_placa': 'Automatic detection — keep the plate inside the frame',
      'acerca_aleja_placa': 'Move the plate closer or farther until it looks sharp',
      'no_se_detecto_placa_reintentando': "Couldn't detect the plate, retrying...",
      'usar_teclado_button': 'Use keyboard instead',
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
