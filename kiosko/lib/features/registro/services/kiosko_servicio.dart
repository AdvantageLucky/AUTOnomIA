import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:kigo_kiosco/core/models/kiosko_config.dart';

class KioskoServicio {
  static const String _baseUrl = 'http://127.0.0.1:8000/api/v1';
  static const int _accesoId = 1;
  static const String _claveKiosko = 'J45PH3K7DUKQDZMR';

  String? _sessionToken;

  Future<void> _ensureLogin() async {
    if (_sessionToken != null) return;

    final response = await http
        .post(
          Uri.parse('$_baseUrl/auth/kiosko/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'kiosko_id': _accesoId,
            'clave_kiosko': _claveKiosko,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 201) {
      _sessionToken = jsonDecode(response.body)['token'] as String;
    } else {
      throw Exception('Error al autenticar kiosko (${response.statusCode})');
    }
  }

  Future<KioskoConfig> obtenerConfig() async {
    await _ensureLogin();
    final response = await http.get(
      Uri.parse('$_baseUrl/kioskos/$_accesoId/config'),
      headers: {'Authorization': 'Bearer $_sessionToken'},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return KioskoConfig.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Error al obtener config (${response.statusCode})');
  }

  /// Inicia el stream SSE de la config y llama [onConfig] cada vez que el
  /// admin la actualiza. Se reconecta automáticamente tras 5 s si se pierde.
  void escucharConfigStream(void Function(KioskoConfig) onConfig) {
    _sseLoop(onConfig);
  }

  Future<void> _sseLoop(void Function(KioskoConfig) onConfig) async {
    while (true) {
      try {
        await _ensureLogin();
        final client = http.Client();
        final request = http.Request(
          'GET',
          Uri.parse('$_baseUrl/kioskos/$_accesoId/config/stream'),
        )..headers['Authorization'] = 'Bearer $_sessionToken';

        final response = await client.send(request);
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
      } catch (e) {
        debugPrint('SSE config stream error: $e — reconectando en 5s');
      }
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  Future<Map<String, dynamic>> registrarVisitante({
    required String titular,
    required String claveElector,
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
      claveElector: claveElector,
      curp: curp,
      motivoVisita: motivoVisita,
      casaDestino: casaDestino,
      placa: placa,
      pathFotoIne: pathFotoIne,
      pathFotoRostro: pathFotoRostro,
      reintento: false,
    );
  }

  Future<List<Map<String, dynamic>>> obtenerDestinos() async {
    await _ensureLogin();
    final response = await http.get(
      Uri.parse('$_baseUrl/kioskos/$_accesoId/destinos/'),
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
      Uri.parse('$_baseUrl/kioskos/$_accesoId/visitas/$visitaId'),
      headers: {'Authorization': 'Bearer $_sessionToken'},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Error al consultar estado de visita (${response.statusCode})');
  }

  Future<Map<String, dynamic>> _enviarRegistro({
    required String titular,
    required String claveElector,
    required String curp,
    required String motivoVisita,
    required String casaDestino,
    required String placa,
    required String pathFotoIne,
    String? pathFotoRostro,
    required bool reintento,
  }) async {
    final uri = Uri.parse('$_baseUrl/kioskos/$_accesoId/visitas/');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $_sessionToken'
      ..fields['titular'] = titular
      ..fields['tipo_visitante'] = 'VISITANTE'
      ..fields['tipo_documento'] = 'INE'
      ..fields['clave_lector'] = claveElector
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
      await _ensureLogin();
      return _enviarRegistro(
        titular: titular,
        claveElector: claveElector,
        curp: curp,
        motivoVisita: motivoVisita,
        casaDestino: casaDestino,
        placa: placa,
        pathFotoIne: pathFotoIne,
        pathFotoRostro: pathFotoRostro,
        reintento: true,
      );
    }

    final body = jsonDecode(response.body);
    throw Exception(body['error'] ?? 'Error ${response.statusCode}');
  }
}
