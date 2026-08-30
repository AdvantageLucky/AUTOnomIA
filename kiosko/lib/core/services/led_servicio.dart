import 'package:flutter/services.dart';

/// Controla el LED RGBW del hardware Telpo F10 (F10SDK/doc/Telpo F10SDK
/// Manual.docx, sección LED) para dar feedback visual del resultado de un
/// registro: verde si se aprueba, rojo si se rechaza. Silencioso ante
/// cualquier falla — el hardware puede no tener el LED (otro modelo,
/// emulador) y eso nunca debe tronar la pantalla de resultado.
class LedServicio {
  static const MethodChannel _canal = MethodChannel('com.example.kigo_kiosco/led');

  Future<void> mostrarAprobado() => _setColor('verde');

  Future<void> mostrarRechazado() => _setColor('rojo');

  Future<void> apagar() async {
    try {
      await _canal.invokeMethod('apagar');
    } on PlatformException {
      // Sin LED que apagar, no hay nada que hacer.
    }
  }

  Future<void> _setColor(String color) async {
    try {
      await _canal.invokeMethod('setColor', {'color': color});
    } on PlatformException {
      // Ver comentario de clase: falla silenciosa.
    }
  }
}
