import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../utils/constants.dart';

class RegistroService {
  static const _base = AppConstants.apiBaseUrl;

  Future<Map<String, dynamic>> buscarCentro(String codigo) async {
    final uri = Uri.parse('$_base/centros/buscar').replace(
      queryParameters: {'codigo': codigo},
    );
    final res = await http.get(uri).timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 404) throw Exception('Centro no encontrado');
    throw Exception('Error ${res.statusCode}');
  }

  Future<List<String>> listarDestinos(String codigoCentro) async {
    final uri = Uri.parse('$_base/centros/$codigoCentro/destinos');
    final res = await http.get(uri).timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return (body['destinos'] as List<dynamic>? ?? []).cast<String>();
    }
    return const [];
  }

  Future<void> autoRegistrar({
    required String codigoCentro,
    required String nombre,
    required String apellidoPaterno,
    required String apellidoMaterno,
    required String telefono,
    required String casaDestino,
    required String pin,
    String? fotoCaraPath,
  }) async {
    final uri = Uri.parse('$_base/centros/$codigoCentro/residentes/auto-registro');
    final req = http.MultipartRequest('POST', uri)
      ..fields['nombre'] = nombre
      ..fields['apellido_paterno'] = apellidoPaterno
      ..fields['apellido_materno'] = apellidoMaterno
      ..fields['telefono'] = telefono
      ..fields['casa_destino'] = casaDestino
      ..fields['pin'] = pin;

    if (fotoCaraPath != null) {
      req.files.add(await http.MultipartFile.fromPath(
        'foto_cara',
        fotoCaraPath,
        contentType: MediaType('image', 'jpeg'),
      ));
    }

    final streamed = await req.send().timeout(const Duration(seconds: 20));
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode == 201) return;
    final body = jsonDecode(res.body);
    throw Exception(body['error'] ?? 'Error ${res.statusCode}');
  }

  Future<String> consultarEstado({
    required String codigoCentro,
    required String casaDestino,
    required String pin,
  }) async {
    final uri = Uri.parse('$_base/centros/$codigoCentro/residentes/estado').replace(
      queryParameters: {'casa_destino': casaDestino, 'pin': pin},
    );
    final res = await http.get(uri).timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as Map<String, dynamic>)['status'] as String;
    }
    if (res.statusCode == 401) throw Exception('Credenciales incorrectas');
    throw Exception('Error ${res.statusCode}');
  }
}
