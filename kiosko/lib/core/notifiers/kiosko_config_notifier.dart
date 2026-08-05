import 'package:flutter/foundation.dart';
import 'package:kigo_kiosco/core/models/kiosko_config.dart';
import 'package:kigo_kiosco/features/registro/services/kiosko_servicio.dart';

/// Mantiene la KioskoConfig activa y la actualiza en tiempo real via SSE.
/// Se provee en el root del árbol para que cualquier widget pueda leerla.
class KioskoConfigNotifier extends ChangeNotifier {
  KioskoConfig _config = KioskoConfig.defaults;
  bool _cargando = true;

  KioskoConfig get config => _config;
  bool get cargando => _cargando;

  final KioskoServicio _servicio;

  KioskoConfigNotifier(this._servicio);

  /// Carga la config inicial y luego suscribe al stream SSE.
  /// Tolerante a fallos: si el backend no responde, usa los valores por defecto.
  Future<void> inicializar() async {
    try {
      _config = await _servicio
          .obtenerConfig()
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // backend no disponible — los defaults permiten que el kiosko opere
    }
    _cargando = false;
    notifyListeners();

    _servicio.escucharConfigStream((cfg) {
      _config = cfg;
      notifyListeners();
    });
  }
}
