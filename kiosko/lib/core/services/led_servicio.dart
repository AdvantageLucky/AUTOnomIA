import 'package:flutter/services.dart';

/// Controla el LED RGBW del hardware Telpo F10 (F10SDK/doc/Telpo F10SDK
/// Manual.docx, sección LED) para dar feedback visual y luz de apoyo:
/// - Verde: Aprobado / Acceso autorizado
/// - Rojo: Rechazado / Error / PIN incorrecto
/// - Blanco: Iluminación de apoyo durante escaneo de QR, rostro o documento
/// - Azul: Procesando / Espera
/// - Ámbar: sin conexión a internet (no hay canal ámbar en el hardware --
///   el lado nativo lo logra prendiendo rojo+verde a la vez)
///
/// Silencioso ante cualquier falla — el hardware puede no tener el LED
/// (otro modelo, emulador) y eso nunca debe tronar la pantalla.
class LedServicio {
  static const MethodChannel _canal = MethodChannel('com.example.kigo_kiosco/led');

  Future<void> mostrarAprobado() => _setColor('verde');

  Future<void> mostrarRechazado() => _setColor('rojo');

  Future<void> encenderIluminacion() => _setColor('blanco');

  Future<void> encenderAzul() => _setColor('azul');

  Future<void> mostrarOffline() => _setColor('amarillo');

  Future<void> apagar() async {
    try {
      await _canal.invokeMethod('apagar');
    } on PlatformException {
      // Sin LED que apagar, no hay nada que hacer.
    } catch (_) {}
  }

  Future<void> _setColor(String color) async {
    try {
      await _canal.invokeMethod('setColor', {'color': color});
    } on PlatformException {
      // Ver comentario de clase: falla silenciosa.
    } catch (_) {}
  }
}
