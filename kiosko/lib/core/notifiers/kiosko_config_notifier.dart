import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:kigo_kiosco/core/models/kiosko_config.dart';
import 'package:kigo_kiosco/features/registro/services/kiosko_servicio.dart';

/// Presupuesto total del arranque: lo que la pantalla de splash puede tardar
/// antes de que demos la config por perdida y tiremos del respaldo en disco.
///
/// Eran 5s, y el GET de dentro tenía su propio límite de 10: el de fuera
/// siempre ganaba, así que el de dentro era código muerto y cualquier red
/// lenta pero sana se descartaba a los 5s aunque la respuesta viniera en
/// camino. Peor: esos 5s también tenían que alcanzar para el 401 -> re-login
/// -> GET otra vez, que no cabe ni de lejos.
///
/// 12 cubre el camino sano (GET de 5) y el del 401 con holgura, sin dejar a
/// un visitante mirando el splash. Si aun así se agota, el kiosko ya no cae
/// en los defaults vacíos: arranca con la última config buena del disco.
const Duration presupuestoArranqueConfig = Duration(seconds: 12);

class KioskoConfigNotifier extends ChangeNotifier {
  KioskoConfig _config = KioskoConfig.defaults;
  bool _cargando = true;
  bool _necesitaActivacion = false;
  Timer? _heartbeatTimer;

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
      _config =
          await _servicio.obtenerConfig().timeout(presupuestoArranqueConfig);
      _cargando = false;
      notifyListeners();
      onSesionValida?.call();
      _iniciarHeartbeat();
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
      // Backend no disponible. Antes se arrancaba con KioskoConfig.defaults
      // -- el kiosko opera, pero ahí `mensajeBienvenida` es cadena vacía y el
      // escáner QR lee eso como "no hay pastilla que mostrar": el panel se
      // quedaba sin el nombre del fraccionamiento hasta el siguiente arranque
      // con red. Y no se recuperaba solo, porque el SSE únicamente emite
      // cuando el admin guarda cambios, no manda el estado al conectarse.
      //
      // Así que se arranca con la última config buena que haya en disco. Es
      // vieja, pero es la del kiosko; los defaults no son de nadie.
      final respaldo = await _servicio.configRespaldo();
      if (respaldo != null) {
        _config = respaldo;
      } else {
        // Sin respaldo entero (kiosko recién activado que nunca completó un
        // GET) queda el teléfono suelto del arranque anterior: es justo el
        // arranque en frío sin internet donde el botón "llamar al
        // administrador" más hace falta.
        final telRespaldo = await _servicio.telefonoContactoRespaldo();
        if (telRespaldo.isNotEmpty) {
          _config = _config.withTelefonoContacto(telRespaldo);
        }
      }
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
    _heartbeatTimer?.cancel();
    notifyListeners();
  }

  /// 30s, no los 8s de ConnectivityService -- el heartbeat solo alimenta el
  /// badge "en línea" del dashboard admin, no necesita ese ritmo.
  void _iniciarHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _servicio.ping();
    });
  }

  /// Llamar cuando el dispositivo completa la activación RFC 8628.
  Future<void> reinicializar() => inicializar();

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    // El loop SSE vive en el servicio, que es un singleton: sin esto seguiría
    // reconectando y llamando a notifyListeners() sobre este notifier ya
    // desechado.
    _servicio.detenerConfigStream();
    super.dispose();
  }
}
