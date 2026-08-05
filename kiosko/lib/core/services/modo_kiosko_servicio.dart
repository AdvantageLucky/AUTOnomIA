import 'package:flutter/services.dart';

class ModoKioskoServicio {
  static const MethodChannel _canal =
      MethodChannel('com.example.kigo_kiosco/kiosk_mode');

  Future<void> salirDeModoKiosko() async {
    try {
      await _canal.invokeMethod('exitKioskMode');
    } on PlatformException {
      // Si el canal falla, el operador ya tiene la app abierta y puede
      // reintentar o usar el escape de sistema (mantener atrás + recientes).
    }
  }
}
