import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:kigo_kiosco/core/models/kiosko_config.dart';
import 'package:kigo_kiosco/features/activacion/models/device_solicitud.dart';

class DeviceNotActivatedException implements Exception {}

class DeviceAuthorizationPendingException implements Exception {}

class DeviceExpiredException implements Exception {}

class KioskoServicio {
  static const String _baseUrl = 'http://localhost:8000/api/v1';
  static const String _keyToken = 'kiosko_token';
  static const String _keyKioskoId = 'kiosko_id';
  static const String _keyClave = 'kiosko_clave';

  static final KioskoServicio _instance = KioskoServicio._internal();
  factory KioskoServicio() => _instance;
  KioskoServicio._internal();

  final _storage = const FlutterSecureStorage();

  String? _sessionToken;
  int? _kioskoId;

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

  Future<Map<String, dynamic>> registrarVisitante({
    required String titular,
    required String curp,
    required String motivoVisita,
    required String casaDestino,
    String placa = '',
    required String pathFotoIne,
    String? pathFotoRostro,
  }) async {
    await _ensureLogin();
    return _enviarRegistro(
      titular: titular,
      curp: curp,
      motivoVisita: motivoVisita,
      casaDestino: casaDestino,
      placa: placa,
      pathFotoIne: pathFotoIne,
      pathFotoRostro: pathFotoRostro,
      reintento: false,
    );
  }

  Future<Map<String, dynamic>> usarInvitacion(String token) async {
    await _ensureLogin();
    final response = await http.post(
      Uri.parse('$_baseUrl/kioskos/$_kioskoId/invitaciones/$token/usar'),
      headers: {'Authorization': 'Bearer $_sessionToken'},
    ).timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) return jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 404) throw Exception('Invitación no válida, expirada o agotada');
    throw Exception('Error al procesar invitación (${response.statusCode})');
  }

  Future<Map<String, dynamic>> validarPinResidente(String pin) async {
    await _ensureLogin();
    final response = await http.post(
      Uri.parse('$_baseUrl/kioskos/$_kioskoId/residentes/login'),
      headers: {
        'Authorization': 'Bearer $_sessionToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'pin': pin}),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    if (response.statusCode == 401) {
      throw Exception('PIN incorrecto');
    }
    throw Exception('Error al validar PIN (${response.statusCode})');
  }

  Future<Map<String, dynamic>> verificarRostroResidente(List<double> embedding) async {
    await _ensureLogin();
    final response = await http.post(
      Uri.parse('$_baseUrl/kioskos/$_kioskoId/residentes/verificar-rostro'),
      headers: {
        'Authorization': 'Bearer $_sessionToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'embedding': embedding}),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    if (response.statusCode == 401) {
      throw Exception('Rostro no reconocido');
    }
    throw Exception('Error al verificar rostro (${response.statusCode})');
  }

  Future<List<Map<String, dynamic>>> obtenerDestinos() async {
    await _ensureLogin();
    final response = await http.get(
      Uri.parse('$_baseUrl/kioskos/$_kioskoId/destinos/'),
      headers: {'Authorization': 'Bearer $_sessionToken'},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List;
      return list.cast<Map<String, dynamic>>();
    }
    throw Exception('Error al obtener destinos (${response.statusCode})');
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
    required String motivoVisita,
    required String casaDestino,
    required String placa,
    required String pathFotoIne,
    String? pathFotoRostro,
    required bool reintento,
  }) async {
    final uri = Uri.parse('$_baseUrl/kioskos/$_kioskoId/visitas/');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $_sessionToken'
      ..fields['titular'] = titular
      ..fields['tipo_visitante'] = 'VISITANTE'
      ..fields['tipo_documento'] = 'INE'
      ..fields['curp'] = curp
      ..fields['motivo_visita'] = motivoVisita
      ..fields['casa_destino'] = casaDestino
      ..fields['placa'] = placa;

    request.files.add(
      await http.MultipartFile.fromPath(
        'foto_documento', pathFotoIne,
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    if (pathFotoRostro != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'foto_rostro', pathFotoRostro,
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
          titular: titular, curp: curp, motivoVisita: motivoVisita,
          casaDestino: casaDestino, placa: placa,
          pathFotoIne: pathFotoIne, pathFotoRostro: pathFotoRostro,
          reintento: true,
        );
      }
      await cerrarSesion();
      throw DeviceNotActivatedException();
    }

    final body = jsonDecode(response.body);
    throw Exception(body['error'] ?? 'Error ${response.statusCode}');
  }
}
