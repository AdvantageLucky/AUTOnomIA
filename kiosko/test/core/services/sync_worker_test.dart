import 'package:flutter_test/flutter_test.dart';
import 'package:kigo_kiosco/core/services/connectivity_service.dart';
import 'package:kigo_kiosco/core/services/local_cache_db.dart';
import 'package:kigo_kiosco/core/services/sync_worker.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late LocalCacheDb cache;
  late ConnectivityService connectivity;

  setUp(() async {
    cache = LocalCacheDb.enMemoria();
    await cache.iniciar();
    connectivity = ConnectivityService(pingHealth: () async => true);
  });

  tearDown(() async {
    await cache.cerrar();
  });

  test('drena la cola en orden y marca cada uno como synced', () async {
    await cache.encolarVisita(clientId: 'a', tipo: 'visitante_nuevo', payload: {}, fotoPaths: const {});
    await cache.encolarVisita(clientId: 'b', tipo: 'visitante_nuevo', payload: {}, fotoPaths: const {});

    final procesados = <String>[];
    final worker = SyncWorker(
      cache: cache,
      connectivity: connectivity,
      refrescarSnapshot: () async {},
      reproducirRegistro: (registro) async {
        procesados.add(registro['client_id'] as String);
        return {'ok': true};
      },
    );

    await worker.sincronizarAhora();

    expect(procesados, ['a', 'b']);
    expect(await cache.obtenerColaPendiente(), isEmpty);
  });

  test('un conflicto detiene solo ese registro, sigue con los demas', () async {
    await cache.encolarVisita(clientId: 'a', tipo: 'invitacion', payload: {}, fotoPaths: const {});
    await cache.encolarVisita(clientId: 'b', tipo: 'visitante_nuevo', payload: {}, fotoPaths: const {});

    final worker = SyncWorker(
      cache: cache,
      connectivity: connectivity,
      refrescarSnapshot: () async {},
      reproducirRegistro: (registro) async {
        if (registro['client_id'] == 'a') {
          throw SyncConflictException('invitacion ya usada');
        }
        return {'ok': true};
      },
    );

    await worker.sincronizarAhora();

    final pendientes = await cache.obtenerColaPendiente();
    expect(pendientes, isEmpty); // 'a' pasa a conflicto, 'b' a synced — ninguno queda pendiente
  });

  test('un error de red detiene el drenado sin marcar nada a medias', () async {
    await cache.encolarVisita(clientId: 'a', tipo: 'visitante_nuevo', payload: {}, fotoPaths: const {});
    await cache.encolarVisita(clientId: 'b', tipo: 'visitante_nuevo', payload: {}, fotoPaths: const {});

    final worker = SyncWorker(
      cache: cache,
      connectivity: connectivity,
      refrescarSnapshot: () async {},
      reproducirRegistro: (registro) async {
        throw Exception('sin red a medio camino');
      },
    );

    await worker.sincronizarAhora();

    final pendientes = await cache.obtenerColaPendiente();
    expect(pendientes.length, 2); // ninguno se toco
  });
}
