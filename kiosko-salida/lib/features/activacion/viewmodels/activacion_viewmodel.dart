import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:kigo_salida/features/activacion/models/device_solicitud.dart';
import 'package:kigo_salida/features/salida/services/salida_servicio.dart';

enum ActivacionEstado { solicitando, esperando, aprobado, expirado, error }

class ActivacionViewModel extends ChangeNotifier {
  ActivacionEstado _estado = ActivacionEstado.solicitando;
  DeviceSolicitud? _solicitud;
  String? _errorMsg;
  int _segundosRestantes = 0;
  Timer? _countdownTimer;
  Timer? _pollingTimer;

  ActivacionEstado get estado => _estado;
  DeviceSolicitud? get solicitud => _solicitud;
  String? get errorMsg => _errorMsg;
  int get segundosRestantes => _segundosRestantes;

  final SalidaServicio _servicio;

  ActivacionViewModel(this._servicio);

  Future<void> iniciar() async {
    _estado = ActivacionEstado.solicitando;
    _solicitud = null;
    _errorMsg = null;
    _cancelarTimers();
    notifyListeners();

    try {
      _solicitud = await _servicio.solicitarCodigo();
    } catch (e) {
      _estado = ActivacionEstado.error;
      _errorMsg = 'No se pudo contactar al servidor. Verifica la conexión.';
      notifyListeners();
      return;
    }

    _estado = ActivacionEstado.esperando;
    _segundosRestantes = _solicitud!.expiresIn;
    notifyListeners();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_segundosRestantes <= 0) {
        _cancelarTimers();
        _estado = ActivacionEstado.expirado;
        notifyListeners();
        return;
      }
      _segundosRestantes--;
      notifyListeners();
    });

    _pollingTimer = Timer.periodic(
      Duration(seconds: _solicitud!.interval),
      (_) => _poll(),
    );
  }

  Future<void> _poll() async {
    if (_solicitud == null) return;

    try {
      final resultado = await _servicio.esperarToken(_solicitud!.deviceCode);
      _cancelarTimers();
      await _servicio.guardarSesion(resultado.token, resultado.kioskoId);
      _estado = ActivacionEstado.aprobado;
      notifyListeners();
    } on DeviceAuthorizationPendingException {
      // normal: seguir esperando
    } on DeviceExpiredException {
      _cancelarTimers();
      _estado = ActivacionEstado.expirado;
      notifyListeners();
    } catch (e) {
      // error de red -- no interrumpir el polling, el countdown ya limita el tiempo
    }
  }

  void _cancelarTimers() {
    _countdownTimer?.cancel();
    _pollingTimer?.cancel();
    _countdownTimer = null;
    _pollingTimer = null;
  }

  @override
  void dispose() {
    _cancelarTimers();
    super.dispose();
  }
}
