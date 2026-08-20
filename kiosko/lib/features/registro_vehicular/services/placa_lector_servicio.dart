/* PUNTO DE INTEGRACIÓN CON HARDWARE DEDICADO DE LECTURA DE PLACAS */

/// Lee la placa del vehículo sin intervención del conductor — pensado para
/// una cámara IP o hardware especial de detección de placas, aparte de la
/// cámara con la que el kiosko captura INE/rostro. Ese hardware todavía no
/// existe, así que hoy corre [MockPlacaLectorServicio]; sustituirla es el
/// único cambio necesario cuando se defina el protocolo del dispositivo real
/// (polling a una API local, webhook al backend, etc. — ver #49).
abstract class PlacaLectorServicio {
  /// Se dispara al iniciar el flujo vehicular, en paralelo con INE/rostro.
  /// Se resuelve con la placa leída, o null si no hubo lectura a tiempo —
  /// la UI cae al teclado manual en ese caso.
  Future<String?> leer();
}

/// Sin hardware real todavía: siempre resuelve a null tras una espera
/// razonable, así el flujo vehicular ejercita consistentemente el respaldo
/// manual en vez de inventar una placa falsa que podría colarse en un
/// registro real durante pruebas en campo.
class MockPlacaLectorServicio implements PlacaLectorServicio {
  @override
  Future<String?> leer() async {
    await Future.delayed(const Duration(seconds: 5));
    return null;
  }
}
