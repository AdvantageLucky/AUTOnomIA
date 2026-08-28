import 'package:flutter/foundation.dart';
import 'package:kigo_kiosco/core/models/kiosko_config.dart';
import 'package:kigo_kiosco/features/registro/services/kiosko_servicio.dart';

class KioskoConfigNotifier extends ChangeNotifier {
  KioskoConfig _config = KioskoConfig.defaults;
  bool _cargando = true;
  bool _necesitaActivacion = false;

  KioskoConfig get config => _config;
  bool get cargando => _cargando;
  bool get necesitaActivacion => _necesitaActivacion;

  final KioskoServicio _servicio;
  final Future<void> Function()? onSesionValida;

  KioskoConfigNotifier(this._servicio, {this.onSesionValida});

  Future<void> inicializar() async {
    _cargando = true;
    _necesitaActivacion = false;
    notifyListeners();

    try {
      _config = await _servicio
          .obtenerConfig()
          .timeout(const Duration(seconds: 5));
      _cargando = false;
      notifyListeners();
      onSesionValida?.call();
      _servicio.escucharConfigStream(
        (cfg) {
          _config = cfg;
          notifyListeners();
        },
        onRevocado: _onSesionRevocada,
      );
    } on DeviceNotActivatedException {
      _cargando = false;
      _necesitaActivacion = true;
      notifyListeners();
    } catch (_) {
      // Backend no disponible — los defaults permiten que el kiosko opere
      _cargando = false;
      notifyListeners();
      _servicio.escucharConfigStream(
        (cfg) {
          _config = cfg;
          notifyListeners();
        },
        onRevocado: _onSesionRevocada,
      );
    }
  }

  void _onSesionRevocada() {
    _necesitaActivacion = true;
    notifyListeners();
  }

  /// Llamar cuando el dispositivo completa la activación RFC 8628.
  Future<void> reinicializar() => inicializar();
}
