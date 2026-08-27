import 'dart:async';

import 'package:kigo_kiosco/core/services/connectivity_service.dart';
import 'package:kigo_kiosco/core/services/local_cache_db.dart';

/// Se lanza cuando el backend rechaza un registro por un conflicto de
/// negocio (ej. invitacion ya usada por otro kiosko) — distinto de un error
/// de red, que debe detener el drenado en vez de saltarse el registro.
class SyncConflictException implements Exception {
  final String mensaje;
  SyncConflictException(this.mensaje);
}

/// Mantiene el snapshot local fresco mientras hay red, y drena la cola de
/// visitas pendientes cuando se reconecta — ver spec en
/// docs/superpowers/specs/2026-08-26-modo-offline-kiosko-design.md.
class SyncWorker {
  static const _intervaloRefresh = Duration(minutes: 5);

  final LocalCacheDb cache;
  final ConnectivityService connectivity;
  final Future<void> Function() refrescarSnapshot;
  final Future<Map<String, dynamic>> Function(Map<String, dynamic> registro) reproducirRegistro;

  Timer? _timerRefresh;
  bool _sincronizando = false;

  SyncWorker({
    required this.cache,
    required this.connectivity,
    required this.refrescarSnapshot,
    required this.reproducirRegistro,
  });

  Future<void> iniciar() async {
    connectivity.addListener(_onConnectivityChanged);
    if (!connectivity.isOffline) {
      await sincronizarAhora();
    }
    _timerRefresh = Timer.periodic(_intervaloRefresh, (_) {
      if (!connectivity.isOffline) sincronizarAhora();
    });
  }

  void _onConnectivityChanged() {
    if (!connectivity.isOffline) {
      sincronizarAhora();
    }
  }

  /// Refresca el snapshot y drena la cola pendiente, en ese orden. Se
  /// protege contra corridas simultaneas (el timer y un cambio de
  /// conectividad podrian disparar esto casi al mismo tiempo).
  Future<void> sincronizarAhora() async {
    if (_sincronizando) return;
    _sincronizando = true;
    try {
      await refrescarSnapshot();
      await _drenarCola();
    } finally {
      _sincronizando = false;
    }
  }

  Future<void> _drenarCola() async {
    final pendientes = await cache.obtenerColaPendiente();
    for (final registro in pendientes) {
      final clientId = registro['client_id'] as String;
      try {
        await reproducirRegistro(registro);
        await cache.marcarSincronizada(clientId);
      } on SyncConflictException {
        await cache.marcarConflicto(clientId);
      } catch (_) {
        // Error de red u otro no clasificado: se detiene todo el drenado
        // para no perder el orden ni dejar huecos — se reintenta en el
        // siguiente ciclo (timer o proxima reconexion).
        return;
      }
    }
  }

  void dispose() {
    _timerRefresh?.cancel();
    connectivity.removeListener(_onConnectivityChanged);
  }
}
