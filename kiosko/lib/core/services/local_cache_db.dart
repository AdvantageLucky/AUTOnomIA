import 'dart:convert';

import 'package:sqflite/sqflite.dart';

/// Cache local del kiosko: espejo de solo-lectura de destinos/residentes/
/// invitaciones (se reemplaza completo en cada refresh de snapshot) más la
/// cola de escritura (`visitas_queue`) que nunca se toca en un refresh —
/// solo el SyncWorker la drena registro por registro.
class LocalCacheDb {
  static const _dbName = 'kiosko_cache.db';
  // v3: agrega residentes.es_invitado_frecuente -- distingue a alguien con
  // acceso recurrente prestado por un residente (invitado frecuente) de un
  // residente real, para que el kiosko pueda saludarlos distinto incluso
  // sin conexión.
  static const _dbVersion = 3;

  final String? _pathOverride;
  Database? _db;

  LocalCacheDb() : _pathOverride = null;

  /// Constructor de pruebas: usa una DB en memoria (`sqflite_common_ffi`),
  /// nunca toca el filesystem real.
  LocalCacheDb.enMemoria() : _pathOverride = inMemoryDatabasePath;

  Future<void> iniciar() async {
    final path = _pathOverride ?? await _rutaProduccion();
    _db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE destinos (
            id INTEGER PRIMARY KEY,
            calle TEXT, tipo TEXT, numero TEXT, nombre TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE residentes (
            id INTEGER PRIMARY KEY,
            persona_id INTEGER,
            nombre TEXT, apellido_paterno TEXT, casa_destino TEXT,
            pin_hash TEXT, embedding TEXT,
            es_invitado_frecuente INTEGER DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE invitaciones_activas (
            token TEXT PRIMARY KEY,
            titular TEXT, casa_destino TEXT, expires_at TEXT,
            persona_invitada_id INTEGER,
            permite_reconocimiento_facial INTEGER DEFAULT 0,
            consumida_local INTEGER DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE visitas_queue (
            client_id TEXT PRIMARY KEY,
            tipo TEXT, payload_json TEXT, foto_paths_json TEXT,
            creado_en TEXT, estado TEXT DEFAULT 'pendiente'
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // El cache es un espejo de solo-lectura que se reemplaza completo
        // en cada refresh de snapshot (salvo visitas_queue) — recrearlo
        // desde cero en cada upgrade es seguro, no hay dato del usuario que
        // preservar.
        await db.execute('DROP TABLE IF EXISTS destinos');
        await db.execute('DROP TABLE IF EXISTS residentes');
        await db.execute('DROP TABLE IF EXISTS invitaciones_activas');
        await db.execute('''
          CREATE TABLE destinos (
            id INTEGER PRIMARY KEY,
            calle TEXT, tipo TEXT, numero TEXT, nombre TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE residentes (
            id INTEGER PRIMARY KEY,
            persona_id INTEGER,
            nombre TEXT, apellido_paterno TEXT, casa_destino TEXT,
            pin_hash TEXT, embedding TEXT,
            es_invitado_frecuente INTEGER DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE invitaciones_activas (
            token TEXT PRIMARY KEY,
            titular TEXT, casa_destino TEXT, expires_at TEXT,
            persona_invitada_id INTEGER,
            permite_reconocimiento_facial INTEGER DEFAULT 0,
            consumida_local INTEGER DEFAULT 0
          )
        ''');
      },
    );
  }


  Future<String> _rutaProduccion() async {
    final dir = await getDatabasesPath();
    return '$dir/$_dbName';
  }

  Future<void> cerrar() async {
    await _db?.close();
    _db = null;
  }

  Database get _instancia {
    final db = _db;
    if (db == null) {
      throw StateError('LocalCacheDb.iniciar() no se ha llamado todavia');
    }
    return db;
  }

  // ── Destinos ─────────────────────────────────────────────────────────

  Future<void> reemplazarDestinos(List<Map<String, dynamic>> destinos) async {
    final db = _instancia;
    await db.transaction((txn) async {
      await txn.delete('destinos');
      for (final d in destinos) {
        await txn.insert('destinos', d);
      }
    });
  }

  Future<List<Map<String, dynamic>>> obtenerDestinos() {
    return _instancia.query('destinos');
  }

  // ── Residentes ───────────────────────────────────────────────────────

  Future<void> reemplazarResidentes(List<Map<String, dynamic>> residentes) async {
    final db = _instancia;
    await db.transaction((txn) async {
      await txn.delete('residentes');
      for (final r in residentes) {
        final copia = Map<String, dynamic>.from(r);
        if (copia['embedding'] is List) {
          copia['embedding'] = jsonEncode(copia['embedding']);
        }
        await txn.insert('residentes', copia);
      }
    });
  }

  Future<List<Map<String, dynamic>>> obtenerResidentes() async {
    final rows = await _instancia.query('residentes');
    return rows.map((r) {
      final copia = Map<String, dynamic>.from(r);
      final embeddingRaw = copia['embedding'];
      if (embeddingRaw is String && embeddingRaw.isNotEmpty) {
        copia['embedding'] = (jsonDecode(embeddingRaw) as List).cast<double>();
      } else {
        copia['embedding'] = <double>[];
      }
      // SQLite no tiene booleano nativo -- vuelve como int (0/1).
      copia['es_invitado_frecuente'] = copia['es_invitado_frecuente'] == 1;
      return copia;
    }).toList();
  }

  // ── Invitaciones ─────────────────────────────────────────────────────

  Future<void> reemplazarInvitaciones(List<Map<String, dynamic>> invitaciones) async {
    final db = _instancia;
    await db.transaction((txn) async {
      await txn.delete('invitaciones_activas');
      for (final inv in invitaciones) {
        await txn.insert('invitaciones_activas', {
          ...inv,
          'consumida_local': 0,
        });
      }
    });
  }

  Future<Map<String, dynamic>?> obtenerInvitacionPorToken(String token) async {
    final rows = await _instancia.query(
      'invitaciones_activas',
      where: 'token = ? AND consumida_local = 0',
      whereArgs: [token],
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<Map<String, dynamic>?> obtenerInvitacionActivaPorPersonaId(int personaId) async {
    final rows = await _instancia.query(
      'invitaciones_activas',
      where: 'persona_invitada_id = ?',
      whereArgs: [personaId],
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> marcarInvitacionConsumidaLocal(String token) {
    return _instancia.update(
      'invitaciones_activas',
      {'consumida_local': 1},
      where: 'token = ?',
      whereArgs: [token],
    );
  }

  // ── Cola de visitas (outbox) ────────────────────────────────────────

  /// [fotoPaths] usa llaves con nombre ('ine', 'rostro', 'placa') en vez de
  /// una lista posicional — evita depender del orden al reproducir el
  /// registro contra el backend real (ver SyncWorker).
  Future<void> encolarVisita({
    required String clientId,
    required String tipo,
    required Map<String, dynamic> payload,
    required Map<String, String> fotoPaths,
  }) {
    return _instancia.insert('visitas_queue', {
      'client_id': clientId,
      'tipo': tipo,
      'payload_json': jsonEncode(payload),
      'foto_paths_json': jsonEncode(fotoPaths),
      'creado_en': DateTime.now().toIso8601String(),
      'estado': 'pendiente',
    });
  }

  Future<List<Map<String, dynamic>>> obtenerColaPendiente() {
    return _instancia.query(
      'visitas_queue',
      where: "estado = 'pendiente'",
      orderBy: 'creado_en ASC',
    );
  }

  Future<void> marcarSincronizada(String clientId) {
    return _instancia.update(
      'visitas_queue',
      {'estado': 'synced'},
      where: 'client_id = ?',
      whereArgs: [clientId],
    );
  }

  Future<void> marcarConflicto(String clientId) {
    return _instancia.update(
      'visitas_queue',
      {'estado': 'conflicto'},
      where: 'client_id = ?',
      whereArgs: [clientId],
    );
  }
}
