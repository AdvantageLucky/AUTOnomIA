import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException, HttpException, HandshakeException, TlsException;
import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:uuid/uuid.dart';
import 'package:kigo_kiosco/core/models/kiosko_config.dart';
import 'package:kigo_kiosco/core/services/coincidencia_facial_local.dart';
import 'package:kigo_kiosco/core/services/connectivity_service.dart';
import 'package:kigo_kiosco/core/services/local_cache_db.dart';
import 'package:kigo_kiosco/features/activacion/models/device_solicitud.dart';

class DeviceNotActivatedException implements Exception {}

/// Token de invitación inválido, expirado, agotado o ya consumido. Tipado
/// aparte (en vez de un Exception genérico) para que SyncWorker pueda
/// distinguirlo de un fallo de red al reproducir un registro offline — este
/// es un rechazo legítimo del backend, no algo que deba reintentarse.
class InvitacionInvalidaException implements Exception {
  final String mensaje;
  InvitacionInvalidaException([this.mensaje = 'Invitación no válida, expirada o agotada']);
  @override
  String toString() => mensaje;
}

class DeviceAuthorizationPendingException implements Exception {}

class DeviceExpiredException implements Exception {}

class KioskoServicio {
  static const String _baseUrl = 'https://homelab.tail8dc7f1.ts.net/api/v1';
  static const String _keyToken = 'kiosko_token';
  static const String _keyKioskoId = 'kiosko_id';
  static const String _keyClave = 'kiosko_clave';

  static final KioskoServicio _instance = KioskoServicio._internal();
  factory KioskoServicio() => _instance;
  KioskoServicio._internal();

  final _storage = const FlutterSecureStorage();

  String? _sessionToken;
  int? _kioskoId;

  final _uuid = const Uuid();
  ConnectivityService? _connectivity;
  LocalCacheDb? _cache;

  /// Debe llamarse una vez al arrancar la app (ver main.dart) antes de que
  /// cualquier flujo de registro intente usar el modo offline. Sin esto,
  /// KioskoServicio se comporta exactamente como antes (siempre en línea).
  void configurarOffline(ConnectivityService connectivity, LocalCacheDb cache) {
    _connectivity = connectivity;
    _cache = cache;
  }

  /// true cuando un error de red (DNS, socket, timeout, host inalcanzable,
  /// o corte de conexión) interrumpió la llamada.
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

  Future<void> _ensureLogin() async {
    if (_sessionToken != null) return;

    final token = await _storage.read(key: _keyToken);
    final kioskoIdStr = await _storage.read(key: _keyKioskoId);
    if (token == null || kioskoIdStr == null) {
      throw DeviceNotActivatedException();
    }
    _sessionToken = token;
    _kioskoId = int.parse(kioskoIdStr);
  }

  // Intenta re-autenticarse silenciosamente con la clave almacenada.
  // Devuelve true si el nuevo token fue obtenido y guardado.
  Future<bool> _reLogin() async {
    final claveKiosko = await _storage.read(key: _keyClave);
    if (claveKiosko == null || _kioskoId == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/kiosko/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'kiosko_id': _kioskoId, 'clave_kiosko': claveKiosko}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final newToken = body['token'] as String;
        await _storage.write(key: _keyToken, value: newToken);
        _sessionToken = newToken;
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> guardarSesion(String token, int kioskoId, {String? claveKiosko}) async {
    await _storage.write(key: _keyToken, value: token);
    await _storage.write(key: _keyKioskoId, value: kioskoId.toString());
    if (claveKiosko != null && claveKiosko.isNotEmpty) {
      await _storage.write(key: _keyClave, value: claveKiosko);
    }
    _sessionToken = token;
    _kioskoId = kioskoId;
  }

  Future<void> cerrarSesion() async {
    await _storage.deleteAll();
    _sessionToken = null;
    _kioskoId = null;
  }

  // ── Device Authorization Grant (RFC 8628) ──────────────────────────────────

  Future<DeviceSolicitud> solicitarCodigo() async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/device/authorize'),
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return DeviceSolicitud.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Error solicitando código (${response.statusCode})');
  }

  Future<({String token, int kioskoId, String claveKiosko})> esperarToken(String deviceCode) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/device/token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'device_code': deviceCode,
        'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
      }),
    ).timeout(const Duration(seconds: 10));

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      return (
        token: body['token'] as String,
        kioskoId: body['kiosko_id'] as int,
        claveKiosko: (body['clave_kiosko'] as String?) ?? '',
      );
    }
    if (response.statusCode == 428 || body['error'] == 'authorization_pending') {
      throw DeviceAuthorizationPendingException();
    }
    if (body['error'] == 'expired_token') {
      throw DeviceExpiredException();
    }
    throw Exception(body['error'] ?? 'Error (${response.statusCode})');
  }

  // ── Config & SSE ────────────────────────────────────────────────────────────

  Future<KioskoConfig> obtenerConfig() async {
    await _ensureLogin();
    var response = await http.get(
      Uri.parse('$_baseUrl/kioskos/$_kioskoId/config/mia'),
      headers: {'Authorization': 'Bearer $_sessionToken'},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 401) {
      _sessionToken = null;
      if (await _reLogin()) {
        response = await http.get(
          Uri.parse('$_baseUrl/kioskos/$_kioskoId/config/mia'),
          headers: {'Authorization': 'Bearer $_sessionToken'},
        ).timeout(const Duration(seconds: 10));
      } else {
        await cerrarSesion();
        throw DeviceNotActivatedException();
      }
    }

    if (response.statusCode == 200) {
      return KioskoConfig.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Error al obtener config (${response.statusCode})');
  }

  /// [onRevocado] se llama si la sesión del kiosko fue revocada (ej. el admin lo
  /// eliminó desde el dashboard) y no se pudo re-autenticar: el dispositivo
  /// debe volver a la pantalla de activación.
  void escucharConfigStream(
    void Function(KioskoConfig) onConfig, {
    VoidCallback? onRevocado,
  }) {
    _sseLoop(onConfig, onRevocado);
  }

  Future<void> _sseLoop(
    void Function(KioskoConfig) onConfig,
    VoidCallback? onRevocado,
  ) async {
    while (true) {
      try {
        await _ensureLogin();
        final client = http.Client();
        final request = http.Request(
          'GET',
          Uri.parse('$_baseUrl/kioskos/$_kioskoId/config/stream'),
        )..headers['Authorization'] = 'Bearer $_sessionToken';

        final response = await client.send(request);

        if (response.statusCode == 401) {
          _sessionToken = null;
          final relogueado = await _reLogin();
          if (!relogueado) {
            await cerrarSesion();
            onRevocado?.call();
            return;
          }
          await Future.delayed(const Duration(seconds: 1));
          continue;
        }

        await response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .forEach((line) {
          if (line.startsWith('data: ')) {
            try {
              final cfg = KioskoConfig.fromJson(
                  jsonDecode(line.substring(6)) as Map<String, dynamic>);
              onConfig(cfg);
            } catch (e) {
              debugPrint('SSE config parse error: $e');
            }
          }
        });
      } on DeviceNotActivatedException {
        onRevocado?.call();
        return;
      } catch (e) {
        debugPrint('SSE config stream error: $e — reconectando en 5s');
      }
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  // ── Visitas ─────────────────────────────────────────────────────────────────

  /// Registra una visita sin invitación (TipoVisitante = VISITANTE).
  ///
  /// La INE siempre es obligatoria para este tipo (ADR-0016); la foto de rostro
  /// y la placa solo se exigen si la config del kiosko las tiene encendidas. Las
  /// visitas con invitación no pasan por aquí sino por [usarInvitacion], que
  /// además consume el token y las deja aprobadas.
  Future<Map<String, dynamic>> registrarVisitante({
    required String titular,
    required String curp,
    required String casaDestino,
    String placa = '',
    String? pathFotoIne,
    String? pathFotoRostro,
    String? pathFotoPlaca,
    String? clientId,
  }) async {
    final connectivity = _connectivity;
    final cache = _cache;
    if (connectivity != null && cache != null && connectivity.isOffline) {
      return _encolarVisitante(
        cache: cache,
        titular: titular,
        curp: curp,
        casaDestino: casaDestino,
        placa: placa,
        pathFotoIne: pathFotoIne,
        pathFotoRostro: pathFotoRostro,
        pathFotoPlaca: pathFotoPlaca,
      );
    }

    try {
      await _ensureLogin();
      return await _enviarRegistro(
        titular: titular,
        curp: curp,
        casaDestino: casaDestino,
        placa: placa,
        tipoVisitante: 'VISITANTE',
        pathFotoIne: pathFotoIne,
        pathFotoRostro: pathFotoRostro,
        pathFotoPlaca: pathFotoPlaca,
        reintento: false,
        clientId: clientId,
      );
    } catch (e) {
      // La red parecía disponible pero la llamada falló a medio camino — si
      // fue un fallo de red real (no un rechazo legítimo del servidor), no
      // se pierde el registro: se encola igual que si hubiéramos detectado
      // el corte de antemano.
      if (cache != null && _esFalloDeRed(e)) {
        return _encolarVisitante(
          cache: cache,
          titular: titular,
          curp: curp,
          casaDestino: casaDestino,
          placa: placa,
          pathFotoIne: pathFotoIne,
          pathFotoRostro: pathFotoRostro,
          pathFotoPlaca: pathFotoPlaca,
        );
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _encolarVisitante({
    required LocalCacheDb cache,
    required String titular,
    required String curp,
    required String casaDestino,
    required String placa,
    String? pathFotoIne,
    String? pathFotoRostro,
    String? pathFotoPlaca,
  }) async {
    final clientId = _uuid.v4();
    await cache.encolarVisita(
      clientId: clientId,
      tipo: 'visitante_nuevo',
      payload: {
        'titular': titular,
        'curp': curp,
        'casa_destino': casaDestino,
        'placa': placa,
      },
      fotoPaths: {
        'ine': ?pathFotoIne,
        'rostro': ?pathFotoRostro,
        'placa': ?pathFotoPlaca,
      },
    );
    // Respuesta sintetizada localmente — misma forma que ya arma
    // _enviarRegistro para RegisterVisita: la UI (resumen_solicitud_view)
    // no distingue "encolado" de "enviado".
    return {
      'id': null,
      'estado': 'PENDIENTE',
      'client_id': clientId,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  /// Valida un token de invitación sin consumirlo. El kiosko lo usa al escanear
  /// el QR para saber a nombre de quién y a qué casa va la visita antes de pedir
  /// las capturas que exija su configuración.
  Future<Map<String, dynamic>> validarInvitacion(String token) async {
    final connectivity = _connectivity;
    final cache = _cache;
    if (connectivity != null && cache != null && connectivity.isOffline) {
      final inv = await cache.obtenerInvitacionPorToken(token);
      if (inv != null) return inv;
      throw Exception('Invitación no válida, expirada o no encontrada');
    }

    try {
      await _ensureLogin();
      final response = await http.get(
        Uri.parse('$_baseUrl/kioskos/$_kioskoId/invitaciones/validar?token=$token'),
        headers: {'Authorization': 'Bearer $_sessionToken'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      if (response.statusCode == 404) {
        throw Exception('Invitación no válida, expirada o agotada');
      }
      if (cache != null) {
        final inv = await cache.obtenerInvitacionPorToken(token);
        if (inv != null) return inv;
      }
      throw Exception('Error al validar invitación (${response.statusCode})');
    } catch (e) {
      if (cache != null && _esFalloDeRed(e)) {
        final inv = await cache.obtenerInvitacionPorToken(token);
        if (inv != null) return inv;
      }
      rethrow;
    }
  }

  /// Consume la invitación y registra la visita como APROBADA.
  ///
  /// Las capturas van en el mismo request: el backend valida contra la config
  /// del kiosko y crea una sola visita. Sin capturas se manda un POST vacío,
  /// que es el caso del kiosko peatonal sin toggles de invitado.
  Future<Map<String, dynamic>> usarInvitacion(
    String token, {
    String placa = '',
    String? curp,
    String? pathFotoIne,
    String? pathFotoRostro,
    String? pathFotoPlaca,
    String? clientId,
  }) async {
    final connectivity = _connectivity;
    final cache = _cache;
    if (connectivity != null && cache != null && connectivity.isOffline) {
      return _usarInvitacionOffline(
        cache, token,
        placa: placa, curp: curp,
        pathFotoIne: pathFotoIne, pathFotoRostro: pathFotoRostro, pathFotoPlaca: pathFotoPlaca,
      );
    }

    try {
      return await _usarInvitacionRemota(
        token,
        placa: placa, curp: curp,
        pathFotoIne: pathFotoIne, pathFotoRostro: pathFotoRostro, pathFotoPlaca: pathFotoPlaca,
        clientId: clientId,
      );
    } catch (e) {
      if (cache != null && _esFalloDeRed(e)) {
        return _usarInvitacionOffline(
          cache, token,
          placa: placa, curp: curp,
          pathFotoIne: pathFotoIne, pathFotoRostro: pathFotoRostro, pathFotoPlaca: pathFotoPlaca,
        );
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _usarInvitacionRemota(
    String token, {
    required String placa,
    String? curp,
    String? pathFotoIne,
    String? pathFotoRostro,
    String? pathFotoPlaca,
    String? clientId,
  }) async {
    await _ensureLogin();
    final uri = Uri.parse('$_baseUrl/kioskos/$_kioskoId/invitaciones/$token/usar');

    // Con client_id (reproduciendo un registro offline) siempre se manda
    // multipart aunque no haya capturas: el backend solo lee client_id del
    // form-data, no de un POST sin cuerpo.
    final sinCapturas = clientId == null &&
        placa.isEmpty &&
        curp == null &&
        pathFotoIne == null &&
        pathFotoRostro == null &&
        pathFotoPlaca == null;

    final http.Response response;
    if (sinCapturas) {
      response = await http.post(
        uri,
        headers: {'Authorization': 'Bearer $_sessionToken'},
      ).timeout(const Duration(seconds: 10));
    } else {
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $_sessionToken'
        ..fields['placa'] = placa
        ..fields['curp'] = curp ?? ''
        ..fields['client_id'] = clientId ?? '';

      for (final foto in [
        ('foto_documento', pathFotoIne),
        ('foto_rostro', pathFotoRostro),
        ('foto_placa', pathFotoPlaca),
      ]) {
        if (foto.$2 == null) continue;
        request.files.add(
          await http.MultipartFile.fromPath(
            foto.$1, foto.$2!,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      final streamed = await request.send().timeout(const Duration(seconds: 20));
      response = await http.Response.fromStream(streamed);
    }

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    if (response.statusCode == 404) {
      throw InvitacionInvalidaException();
    }
    final body = jsonDecode(response.body);
    throw Exception(body['error'] ?? 'Error al procesar invitación (${response.statusCode})');
  }

  Future<Map<String, dynamic>> _usarInvitacionOffline(
    LocalCacheDb cache,
    String token, {
    required String placa,
    String? curp,
    String? pathFotoIne,
    String? pathFotoRostro,
    String? pathFotoPlaca,
  }) async {
    final invitacionLocal = await cache.obtenerInvitacionPorToken(token);
    if (invitacionLocal == null) {
      throw InvitacionInvalidaException();
    }

    final clientId = _uuid.v4();
    await cache.marcarInvitacionConsumidaLocal(token);
    await cache.encolarVisita(
      clientId: clientId,
      tipo: 'invitacion',
      payload: {
        'token': token,
        'placa': placa,
        'curp': curp,
        'titular': invitacionLocal['titular'],
        'casa_destino': invitacionLocal['casa_destino'],
      },
      fotoPaths: {
        'ine': ?pathFotoIne,
        'rostro': ?pathFotoRostro,
        'placa': ?pathFotoPlaca,
      },
    );
    return {
      'titular': invitacionLocal['titular'],
      'casa_destino': invitacionLocal['casa_destino'],
      'visita_id': null,
      'estado': 'APROBADO',
      'placa': placa,
    };
  }

  /// Verifica el QR personal de una Persona (app Kigo): valida su firma y,
  /// en la misma llamada, resuelve si es miembro/invitado/desconocido en
  /// este centro. Si es invitado, el backend ya deja registrada la visita
  /// APROBADA — no hace falta una llamada aparte para consumirla.
  Future<Map<String, dynamic>> verificarQrPersona(int personaId, String firma) async {
    final connectivity = _connectivity;
    final cache = _cache;
    if (connectivity != null && cache != null && connectivity.isOffline) {
      return _verificarQrPersonaOffline(cache, personaId);
    }

    try {
      await _ensureLogin();
      final response = await http.post(
        Uri.parse('$_baseUrl/kioskos/$_kioskoId/personas/verificar-qr'),
        headers: {
          'Authorization': 'Bearer $_sessionToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'persona_id': personaId, 'firma': firma}),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      if (response.statusCode == 401) {
        throw Exception('Código QR inválido');
      }
      if (response.statusCode == 404) {
        throw Exception('No se encontró esa cuenta de Kigo');
      }
      if (cache != null) {
        return _verificarQrPersonaOffline(cache, personaId);
      }
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Error al verificar el QR (${response.statusCode})');
    } catch (e) {
      if (cache != null && _esFalloDeRed(e)) {
        return _verificarQrPersonaOffline(cache, personaId);
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _verificarQrPersonaOffline(LocalCacheDb cache, int personaId) async {
    final residentes = await cache.obtenerResidentes();
    final match = residentes.cast<Map<String, dynamic>?>().firstWhere(
      (r) => r?['id'] == personaId,
      orElse: () => null,
    );
    if (match == null) {
      throw Exception('Cuenta no encontrada en caché local');
    }
    final clientId = _uuid.v4();
    final nombreCompleto = '${match['nombre']} ${match['apellido_paterno']}';
    await cache.encolarVisita(
      clientId: clientId,
      tipo: 'qr_persona',
      payload: {
        'persona_id': personaId,
        'nombre': nombreCompleto,
        'casa_destino': match['casa_destino'],
      },
      fotoPaths: const {},
    );
    return {
      'estado': 'miembro',
      'tipo': 'RESIDENTE',
      'nombre': nombreCompleto,
      'casa_destino': match['casa_destino'],
    };
  }

  Future<Map<String, dynamic>> validarPinResidente(String pin, {int? personaId, String? clientId}) async {
    final connectivity = _connectivity;
    final cache = _cache;
    if (connectivity != null && cache != null && connectivity.isOffline) {
      return _validarPinOffline(cache, pin, personaId: personaId, clientId: clientId);
    }

    try {
      return await _validarPinRemoto(pin, personaId: personaId, clientId: clientId);
    } catch (e) {
      if (cache != null && _esFalloDeRed(e)) {
        return _validarPinOffline(cache, pin, personaId: personaId, clientId: clientId);
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _validarPinRemoto(String pin, {int? personaId, String? clientId}) async {
    await _ensureLogin();
    final bodyMap = <String, dynamic>{'pin': pin};
    if (personaId != null) bodyMap['persona_id'] = personaId;
    if (clientId != null) bodyMap['client_id'] = clientId;

    final response = await http.post(
      Uri.parse('$_baseUrl/kioskos/$_kioskoId/residentes/login'),
      headers: {
        'Authorization': 'Bearer $_sessionToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(bodyMap),
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    if (response.statusCode == 401) {
      throw Exception('PIN incorrecto');
    }
    final body = jsonDecode(response.body);
    throw Exception(body['error'] ?? 'Error al validar PIN (${response.statusCode})');
  }

  Future<Map<String, dynamic>> _validarPinOffline(
    LocalCacheDb cache,
    String pin, {
    int? personaId,
    String? clientId,
  }) async {
    final residentes = await cache.obtenerResidentes();
    final matches = <Map<String, dynamic>>[];
    for (final r in residentes) {
      final pinHash = r['pin_hash'] as String?;
      if (pinHash != null && pinHash.isNotEmpty) {
        try {
          if (BCrypt.checkpw(pin, pinHash)) {
            matches.add(r);
          }
        } catch (_) {}
      }
    }
    if (matches.isEmpty) {
      throw Exception('PIN incorrecto');
    }
    if (matches.length > 1 && personaId == null) {
      return {
        'requiere_seleccion': true,
        'candidatos': matches.map((m) => {
          'persona_id': m['id'],
          'nombre': '${m['nombre']} ${m['apellido_paterno']}',
          'casa_destino': m['casa_destino'],
        }).toList(),
      };
    }
    final match = personaId != null
        ? matches.firstWhere((m) => m['id'] == personaId, orElse: () => matches.first)
        : matches.first;

    final cid = clientId ?? _uuid.v4();
    final nombreCompleto = '${match['nombre']} ${match['apellido_paterno']}';
    await cache.encolarVisita(
      clientId: cid,
      tipo: 'pin_residente',
      payload: {
        'pin': pin,
        'persona_id': match['id'],
        'nombre': nombreCompleto,
        'casa_destino': match['casa_destino'],
      },
      fotoPaths: const {},
    );
    return {
      'nombre': nombreCompleto,
      'casa_destino': match['casa_destino'],
    };
  }

  Future<Map<String, dynamic>> verificarRostroResidente(
    List<double> embedding, {
    String? clientId,
  }) async {
    final connectivity = _connectivity;
    final cache = _cache;
    if (connectivity != null && cache != null && connectivity.isOffline) {
      return _verificarRostroOffline(cache, embedding);
    }

    try {
      return await _verificarRostroRemoto(embedding, clientId: clientId);
    } catch (e) {
      if (cache != null && _esFalloDeRed(e)) {
        return _verificarRostroOffline(cache, embedding);
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _verificarRostroRemoto(
    List<double> embedding, {
    String? clientId,
  }) async {
    await _ensureLogin();
    final response = await http.post(
      Uri.parse('$_baseUrl/kioskos/$_kioskoId/residentes/verificar-rostro'),
      headers: {
        'Authorization': 'Bearer $_sessionToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'embedding': embedding, 'client_id': clientId ?? ''}),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    if (response.statusCode == 401) {
      throw Exception('Rostro no reconocido');
    }
    throw Exception('Error al verificar rostro (${response.statusCode})');
  }

  Future<Map<String, dynamic>> _verificarRostroOffline(
    LocalCacheDb cache,
    List<double> embedding,
  ) async {
    final residentes = await cache.obtenerResidentes();
    final match = mejorCoincidenciaLocal(residentes, embedding);
    if (match == null) {
      throw Exception('Rostro no reconocido');
    }
    final clientId = _uuid.v4();
    final nombreCompleto = '${match['nombre']} ${match['apellido_paterno']}';
    await cache.encolarVisita(
      clientId: clientId,
      tipo: 'rostro_residente',
      payload: {
        'embedding': embedding,
        'nombre': nombreCompleto,
        'casa_destino': match['casa_destino'],
      },
      fotoPaths: const {},
    );
    return {
      'nombre': nombreCompleto,
      'casa_destino': match['casa_destino'],
    };
  }

  Future<List<Map<String, dynamic>>> obtenerDestinos() async {
    final connectivity = _connectivity;
    final cache = _cache;
    if (connectivity != null && cache != null && connectivity.isOffline) {
      final destinosLocales = await cache.obtenerDestinos();
      if (destinosLocales.isNotEmpty) return destinosLocales;
    }

    try {
      await _ensureLogin();
      final response = await http.get(
        Uri.parse('$_baseUrl/kioskos/$_kioskoId/destinos/'),
        headers: {'Authorization': 'Bearer $_sessionToken'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list.cast<Map<String, dynamic>>();
      }
      if (cache != null) {
        final destinosLocales = await cache.obtenerDestinos();
        if (destinosLocales.isNotEmpty) return destinosLocales;
      }
      throw Exception('Error al obtener destinos (${response.statusCode})');
    } catch (e) {
      if (cache != null) {
        final destinosLocales = await cache.obtenerDestinos();
        if (destinosLocales.isNotEmpty) return destinosLocales;
      }
      rethrow;
    }
  }

  // ── Reproducción de la cola offline (solo para SyncWorker) ─────────────────
  //
  // A diferencia de registrarVisitante/usarInvitacion/verificarRostroResidente,
  // estos métodos NO reencolan ante un fallo de red: si lo hicieran, un corte
  // a medio-drenado se tragaría el error silenciosamente y crearía un
  // duplicado en la cola en vez de dejar que SyncWorker detenga el drenado y
  // reintente el mismo client_id en el siguiente ciclo.

  Future<Map<String, dynamic>> reproducirVisitanteNuevo({
    required String titular,
    required String curp,
    required String casaDestino,
    required String placa,
    String? pathFotoIne,
    String? pathFotoRostro,
    String? pathFotoPlaca,
    required String clientId,
  }) async {
    await _ensureLogin();
    return _enviarRegistro(
      titular: titular,
      curp: curp,
      casaDestino: casaDestino,
      placa: placa,
      tipoVisitante: 'VISITANTE',
      pathFotoIne: pathFotoIne,
      pathFotoRostro: pathFotoRostro,
      pathFotoPlaca: pathFotoPlaca,
      reintento: false,
      clientId: clientId,
    );
  }

  Future<Map<String, dynamic>> reproducirInvitacion(
    String token, {
    required String placa,
    String? curp,
    String? pathFotoIne,
    String? pathFotoRostro,
    String? pathFotoPlaca,
    required String clientId,
  }) {
    return _usarInvitacionRemota(
      token,
      placa: placa, curp: curp,
      pathFotoIne: pathFotoIne, pathFotoRostro: pathFotoRostro, pathFotoPlaca: pathFotoPlaca,
      clientId: clientId,
    );
  }

  Future<Map<String, dynamic>> reproducirVerificacionRostro(
    List<double> embedding, {
    required String clientId,
  }) {
    return _verificarRostroRemoto(embedding, clientId: clientId);
  }

  Future<Map<String, dynamic>> reproducirPinResidente(
    String pin, {
    int? personaId,
    required String clientId,
  }) {
    return _validarPinRemoto(pin, personaId: personaId, clientId: clientId);
  }

  Future<Map<String, dynamic>> reproducirQrPersona(
    int personaId, {
    required String clientId,
  }) {
    return _verificarQrPersonaRemoto(personaId, clientId: clientId);
  }

  Future<Map<String, dynamic>> _verificarQrPersonaRemoto(int personaId, {String? clientId}) async {
    await _ensureLogin();
    final response = await http.post(
      Uri.parse('$_baseUrl/kioskos/$_kioskoId/personas/verificar-qr'),
      headers: {
        'Authorization': 'Bearer $_sessionToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'persona_id': personaId, 'firma': '', 'client_id': clientId ?? ''}),
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Error al verificar QR (${response.statusCode})');
  }

  Future<Map<String, dynamic>> obtenerSnapshot() async {
    await _ensureLogin();
    final response = await http.get(
      Uri.parse('$_baseUrl/kioskos/$_kioskoId/sync/snapshot'),
      headers: {'Authorization': 'Bearer $_sessionToken'},
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Error al obtener snapshot (${response.statusCode})');
  }

  Future<Map<String, dynamic>> obtenerEstadoVisita(int visitaId) async {
    await _ensureLogin();
    final response = await http.get(
      Uri.parse('$_baseUrl/kioskos/$_kioskoId/visitas/$visitaId'),
      headers: {'Authorization': 'Bearer $_sessionToken'},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Error al consultar estado de visita (${response.statusCode})');
  }

  Future<Map<String, dynamic>> _enviarRegistro({
    required String titular,
    required String curp,
    required String casaDestino,
    required String placa,
    required String tipoVisitante,
    String? pathFotoIne,
    String? pathFotoRostro,
    String? pathFotoPlaca,
    required bool reintento,
    String? clientId,
  }) async {
    final uri = Uri.parse('$_baseUrl/kioskos/$_kioskoId/visitas/');
    // Sin INE capturada, lo que respalda la visita es la placa: en un acceso
    // vehicular es el único identificador que se toma (ADR-0024).
    final tipoDocumento = pathFotoIne != null ? 'INE' : 'PLACA';
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $_sessionToken'
      ..fields['titular'] = titular
      ..fields['tipo_visitante'] = tipoVisitante
      ..fields['tipo_documento'] = tipoDocumento
      ..fields['curp'] = curp
      ..fields['casa_destino'] = casaDestino
      ..fields['placa'] = placa
      ..fields['client_id'] = clientId ?? '';

    if (pathFotoIne != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'foto_documento', pathFotoIne,
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    }

    if (pathFotoRostro != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'foto_rostro', pathFotoRostro,
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    }

    if (pathFotoPlaca != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'foto_placa', pathFotoPlaca,
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    }

    final streamed = await request.send().timeout(const Duration(seconds: 20));
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    if (response.statusCode == 401 && !reintento) {
      _sessionToken = null;
      final relogueado = await _reLogin();
      if (relogueado) {
        return _enviarRegistro(
          titular: titular, curp: curp,
          casaDestino: casaDestino, placa: placa,
          tipoVisitante: tipoVisitante,
          pathFotoIne: pathFotoIne, pathFotoRostro: pathFotoRostro,
          pathFotoPlaca: pathFotoPlaca,
          reintento: true,
          clientId: clientId,
        );
      }
      await cerrarSesion();
      throw DeviceNotActivatedException();
    }

    final body = jsonDecode(response.body);
    throw Exception(body['error'] ?? 'Error ${response.statusCode}');
  }
}
