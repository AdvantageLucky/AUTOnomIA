import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'package:kigo_salida/features/activacion/models/device_solicitud.dart';

class DeviceNotActivatedException implements Exception {}

class DeviceAuthorizationPendingException implements Exception {}

class DeviceExpiredException implements Exception {}

/// Cliente HTTP de este kiosko -- deliberadamente delgado (a diferencia del
/// KioskoServicio de la app principal, de más de mil líneas) porque este
/// dispositivo solo hace dos cosas: activarse (mismo protocolo RFC 8628 de
/// siempre) y mandar una salida. Nada de INE, PIN, invitaciones ni modo
/// offline -- si algo de eso hiciera falta aquí, sería momento de replantear
/// si este debería ser el kiosko principal en vez de uno aparte.
class SalidaServicio {
  static const String _baseUrl = 'https://homelab.tail8dc7f1.ts.net/api/v1';
  static const String _keyToken = 'salida_token';
  static const String _keyKioskoId = 'salida_kiosko_id';

  static final SalidaServicio _instance = SalidaServicio._internal();
  factory SalidaServicio() => _instance;
  SalidaServicio._internal();

  final _storage = const FlutterSecureStorage();
  String? _sessionToken;
  int? _kioskoId;

  Future<bool> haySesion() async {
    final token = await _storage.read(key: _keyToken);
    final id = await _storage.read(key: _keyKioskoId);
    if (token == null || id == null) return false;
    _sessionToken = token;
    _kioskoId = int.parse(id);
    return true;
  }

  Future<void> guardarSesion(String token, int kioskoId) async {
    await _storage.write(key: _keyToken, value: token);
    await _storage.write(key: _keyKioskoId, value: kioskoId.toString());
    _sessionToken = token;
    _kioskoId = kioskoId;
  }

  Future<void> cerrarSesion() async {
    await _storage.deleteAll();
    _sessionToken = null;
    _kioskoId = null;
  }

  // ── Device Authorization Grant (RFC 8628) -- mismo protocolo que el kiosko principal ──

  Future<DeviceSolicitud> solicitarCodigo() async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/device/authorize'),
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return DeviceSolicitud.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Error solicitando código (${response.statusCode})');
  }

  Future<({String token, int kioskoId})> esperarToken(String deviceCode) async {
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
      return (token: body['token'] as String, kioskoId: body['kiosko_id'] as int);
    }
    if (response.statusCode == 428 || body['error'] == 'authorization_pending') {
      throw DeviceAuthorizationPendingException();
    }
    if (body['error'] == 'expired_token') {
      throw DeviceExpiredException();
    }
    throw Exception(body['error'] ?? 'Error (${response.statusCode})');
  }

  /// Manda la foto de rostro capturada como una nueva entrada de bitácora
  /// tipo SALIDA. Best-effort en el sentido de que un fallo de red no debe
  /// dejar a la persona parada frente al kiosko -- el llamador decide qué
  /// tan tolerante ser con el error (ver CapturaSalidaView).
  Future<void> reportarSalida(String pathFoto) async {
    if (_sessionToken == null || _kioskoId == null) {
      throw DeviceNotActivatedException();
    }

    final uri = Uri.parse('$_baseUrl/kioskos/$_kioskoId/salidas');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $_sessionToken';

    if (File(pathFoto).existsSync()) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'foto', pathFoto,
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    }

    final streamed = await request.send().timeout(const Duration(seconds: 15));
    if (streamed.statusCode != 200) {
      throw Exception('El servidor rechazó la salida (${streamed.statusCode})');
    }
  }
}
