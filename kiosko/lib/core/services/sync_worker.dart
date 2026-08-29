import 'dart:async';
import 'dart:io' show SocketException, HttpException, HandshakeException, TlsException;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:kigo_kiosco/core/services/connectivity_service.dart';
import 'package:kigo_kiosco/core/services/local_cache_db.dart';

/// Se lanza cuando el backend rechaza un registro por un conflicto de
/// negocio (ej. invitacion ya usada por otro kiosko) — distinto de un error
/// de red, que debe detener el drenado en vez de saltarse el registro.
class SyncConflictException implements Exception {
  final String mensaje;
  SyncConflictException(this.mensaje);
  @override
  String toString() => mensaje;
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

  /// Refresca el snapshot y drena la cola pendiente.
  Future<void> sincronizarAhora() async {
    if (_sincronizando) return;
    _sincronizando = true;
    try {
      try {
        await _drenarCola();
      } catch (e) {
        debugPrint('[SyncWorker] Error drenando cola: $e');
      }

      try {
        await refrescarSnapshot();
      } catch (e) {
        debugPrint('[SyncWorker] Error refrescando snapshot: $e');
      }
    } finally {
      _sincronizando = false;
    }
  }

  bool _esFalloDeRed(Object error) {
    if (error is SocketException ||
        error is TimeoutException ||
        error is http.ClientException ||
        error is HttpException ||
        error is HandshakeException ||
        error is TlsException) {
      return true;
    }
    final msg = error.toString().toLowerCase();
    return msg.contains('socket') ||
        msg.contains('failed host lookup') ||
        msg.contains('clientexception') ||
        msg.contains('network') ||
        msg.contains('red') ||
        msg.contains('conexion') ||
        msg.contains('conexión') ||
        msg.contains('connection refused') ||
        msg.contains('connection closed') ||
        msg.contains('connection reset') ||
        msg.contains('timeout') ||
        msg.contains('timed out') ||
        msg.contains('errno') ||
        msg.contains('os error') ||
        msg.contains('handshake') ||
        msg.contains('no address associated') ||
        msg.contains('unreachable');
  }

  Future<void> _drenarCola() async {
    final pendientes = await cache.obtenerColaPendiente();
    if (pendientes.isEmpty) return;
    debugPrint('[SyncWorker] Drenando ${pendientes.length} visitas pendientes...');

    for (final registro in pendientes) {
      final clientId = registro['client_id'] as String;
      final tipo = registro['tipo'] as String;
      try {
        debugPrint('[SyncWorker] Replicando $tipo ($clientId)...');
        await reproducirRegistro(registro);
        await cache.marcarSincronizada(clientId);
        debugPrint('[SyncWorker] Registro $clientId sincronizado exitosamente.');
      } on SyncConflictException catch (e) {
        debugPrint('[SyncWorker] Conflicto en $clientId: ${e.mensaje}');
        await cache.marcarConflicto(clientId);
      } catch (e) {
        if (_esFalloDeRed(e)) {
          debugPrint('[SyncWorker] Fallo de red al replicar $clientId. Se detiene drenado: $e');
          return;
        }
        debugPrint('[SyncWorker] Error no reintentable en $clientId: $e. Marcando como conflicto.');
        await cache.marcarConflicto(clientId);
      }
    }
  }

  void dispose() {
    _timerRefresh?.cancel();
    connectivity.removeListener(_onConnectivityChanged);
  }
}
