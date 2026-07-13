import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class KioskoServicio {
  // --- Configuración hardcodeada para pruebas ---
  static const String _baseUrl = 'http://127.0.0.1:8000/api/v1';
  static const int _accesoId = 20;
  static const String _claveKiosko = '2H4SURVSQOUPKYZU';
  // -----------------------------------------------

  String? _sessionToken;

  Future<void> _ensureLogin() async {
    if (_sessionToken != null) return;

    final response = await http
        .post(
          Uri.parse('$_baseUrl/auth/acceso/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'acceso_id': _accesoId,
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

  Future<Map<String, dynamic>> registrarVisitante({
    required String nombre,
    required String claveElector,
    required String curp,
    required String pathFotoIne,
    required String pathFotoRostro,
  }) async {
    await _ensureLogin();
    return _enviarRegistro(
      nombre: nombre,
      claveElector: claveElector,
      curp: curp,
      pathFotoIne: pathFotoIne,
      pathFotoRostro: pathFotoRostro,
      reintento: false,
    );
  }

  Future<Map<String, dynamic>> _enviarRegistro({
    required String nombre,
    required String claveElector,
    required String curp,
    required String pathFotoIne,
    required String pathFotoRostro,
    required bool reintento,
  }) async {
    final uri = Uri.parse('$_baseUrl/accesos/$_accesoId/visitantes/');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $_sessionToken'
      ..fields['nombre'] = nombre
      ..fields['tipo_documento'] = 'INE'
      ..fields['clave_lector'] = claveElector
      ..fields['curp'] = curp;

    request.files.add(
      await http.MultipartFile.fromPath(
        'foto_documento', pathFotoIne,
        contentType: MediaType('image', 'jpeg'),
      ),
    );
    request.files.add(
      await http.MultipartFile.fromPath(
        'foto_rostro', pathFotoRostro,
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    final streamed = await request.send().timeout(const Duration(seconds: 20));
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    // Sesión expirada o revocada: reintentar una vez con login fresco
    if (response.statusCode == 401 && !reintento) {
      _sessionToken = null;
      await _ensureLogin();
      return _enviarRegistro(
        nombre: nombre,
        claveElector: claveElector,
        curp: curp,
        pathFotoIne: pathFotoIne,
        pathFotoRostro: pathFotoRostro,
        reintento: true,
      );
    }

    final body = jsonDecode(response.body);
    throw Exception(body['error'] ?? 'Error ${response.statusCode}');
  }
}
