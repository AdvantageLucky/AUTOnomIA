import 'package:flutter/services.dart';

/// Abre el relay eléctrico del hardware Telpo F10 (PosUtil.setRelayPower,
/// F10SDK/doc/Telpo F10SDK Manual.docx, sección Relay) que controla la
/// chapa/pluma física de acceso -- hasta ahora nadie llamaba a esto: una
/// visita aprobada solo cambiaba de color en pantalla (LedServicio), la
/// puerta la abría un humano.
///
/// Silencioso ante cualquier falla, igual que LedServicio: el kiosko puede
/// no tener el relay cableado todavía (otro modelo, emulador, torniquete
/// pendiente de instalar) y eso nunca debe tronar la pantalla de resultado.
class RelayServicio {
  static const MethodChannel _canal = MethodChannel('com.example.kigo_kiosco/relay');

  /// Abre el relay [segundos] (default 4, tiempo típico para que pase un
  /// peatón o un vehículo) y lo cierra solo -- el cierre se agenda del lado
  /// nativo, así que ocurre aunque esta pantalla ya no exista.
  Future<void> abrir({int segundos = 4}) async {
    try {
      await _canal.invokeMethod('abrir', {'segundos': segundos});
    } on PlatformException {
      // Ver comentario de clase: falla silenciosa.
    } catch (_) {}
  }
}
