import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Detecta si el kiosko tiene internet real, no solo una interfaz de red
/// activa: connectivity_plus reacciona al instante a cambios de wifi, pero
/// wifi sin salida a internet no cuenta como "en linea" — por eso cada
/// cambio se confirma con un ping a /health antes de declarar isOffline.
class ConnectivityService extends ChangeNotifier {
  static const _baseUrl = 'https://homelab.tail8dc7f1.ts.net';

  final Future<bool> Function() _pingHealth;
  StreamSubscription<List<ConnectivityResult>>? _subscripcion;
  Timer? _pollingTimer;
  bool _isOffline = false;

  ConnectivityService({Future<bool> Function()? pingHealth})
      : _pingHealth = pingHealth ?? _pingHealthReal;

  bool get isOffline => _isOffline;

  static Future<bool> _pingHealthReal() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> iniciar() async {
    await verificarAhora();
    _subscripcion = Connectivity().onConnectivityChanged.listen((_) {
      verificarAhora();
    });
    _pollingTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      verificarAhora();
    });
  }

  /// Corre el chequeo ahora mismo y actualiza [isOffline]. Regresa el nuevo
  /// valor de isOffline (true = sin internet real).
  Future<bool> verificarAhora() async {
    final hayInternet = await _pingHealth();
    final nuevoOffline = !hayInternet;
    if (nuevoOffline != _isOffline) {
      _isOffline = nuevoOffline;
      notifyListeners();
    }
    return _isOffline;
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _subscripcion?.cancel();
    super.dispose();
  }
}
