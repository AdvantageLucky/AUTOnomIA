import 'package:flutter_test/flutter_test.dart';
import 'package:kigo_kiosco/core/services/local_cache_db.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late LocalCacheDb db;

  setUp(() async {
    db = LocalCacheDb.enMemoria();
    await db.iniciar();
  });

  tearDown(() async {
    await db.cerrar();
  });

  test('reemplazarDestinos sustituye el contenido anterior por completo', () async {
    await db.reemplazarDestinos([
      {'id': 1, 'calle': 'Roble', 'tipo': 'casa', 'numero': '10', 'nombre': 'Casa 10'},
    ]);
    await db.reemplazarDestinos([
      {'id': 2, 'calle': 'Pino', 'tipo': 'casa', 'numero': '20', 'nombre': 'Casa 20'},
    ]);

    final destinos = await db.obtenerDestinos();
    expect(destinos.length, 1);
    expect(destinos.first['nombre'], 'Casa 20');
  });

  test('encolarVisita y obtenerColaPendiente respetan el orden de creado_en', () async {
    await db.encolarVisita(
      clientId: 'uuid-1',
      tipo: 'visitante_nuevo',
      payload: {'titular': 'A'},
      fotoPaths: const {},
    );
    await Future.delayed(const Duration(milliseconds: 5));
    await db.encolarVisita(
      clientId: 'uuid-2',
      tipo: 'visitante_nuevo',
      payload: {'titular': 'B'},
      fotoPaths: const {},
    );

    final cola = await db.obtenerColaPendiente();
    expect(cola.length, 2);
    expect(cola[0]['client_id'], 'uuid-1');
    expect(cola[1]['client_id'], 'uuid-2');
  });

  test('marcarSincronizada saca el registro de la cola pendiente', () async {
    await db.encolarVisita(
      clientId: 'uuid-1',
      tipo: 'visitante_nuevo',
      payload: {'titular': 'A'},
      fotoPaths: const {},
    );
    await db.marcarSincronizada('uuid-1');

    final cola = await db.obtenerColaPendiente();
    expect(cola, isEmpty);
  });

  test('invitaciones: marcarInvitacionConsumidaLocal no la vuelve a ofrecer', () async {
    await db.reemplazarInvitaciones([
      {'token': 'tok-1', 'titular': 'Ana', 'casa_destino': 'Casa 1', 'expires_at': null},
    ]);
    await db.marcarInvitacionConsumidaLocal('tok-1');

    final inv = await db.obtenerInvitacionPorToken('tok-1');
    expect(inv, isNull);
  });

  test('residentes: persona_id se guarda y se puede leer aparte de id (membresia)', () async {
    await db.reemplazarResidentes([
      {
        'id': 1, // membresia_id
        'persona_id': 42,
        'nombre': 'Ana',
        'apellido_paterno': 'Ruiz',
        'casa_destino': 'Casa 1',
        'pin_hash': 'hash',
        'embedding': <double>[],
      },
    ]);

    final residentes = await db.obtenerResidentes();
    expect(residentes.first['id'], 1);
    expect(residentes.first['persona_id'], 42);
  });

  test('invitaciones: obtenerInvitacionActivaPorPersonaId encuentra por persona_invitada_id', () async {
    await db.reemplazarInvitaciones([
      {
        'token': 'tok-1',
        'titular': 'Beto',
        'casa_destino': 'Casa 2',
        'expires_at': null,
        'persona_invitada_id': 77,
        'permite_reconocimiento_facial': 1,
      },
    ]);

    final inv = await db.obtenerInvitacionActivaPorPersonaId(77);
    expect(inv, isNotNull);
    expect(inv!['titular'], 'Beto');

    final sinMatch = await db.obtenerInvitacionActivaPorPersonaId(999);
    expect(sinMatch, isNull);
  });

  test('residentes: reemplazarResidentes serializa y obtenerResidentes deserializa el embedding', () async {
    await db.reemplazarResidentes([
      {
        'id': 1,
        'nombre': 'Ana',
        'apellido_paterno': 'Ruiz',
        'casa_destino': 'Casa 1',
        'pin_hash': 'hash',
        'embedding': [1.0, 0.5, 0.0],
      },
    ]);

    final residentes = await db.obtenerResidentes();
    expect(residentes.length, 1);
    expect(residentes.first['embedding'], [1.0, 0.5, 0.0]);
  });
}
