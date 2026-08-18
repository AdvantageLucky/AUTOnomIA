import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
  @override
  String toString() => message;
}

class ApiService {
  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;
  ApiService._();

  String? _jwt;

  Future<String?> _getJwt() async {
    _jwt ??= (await SharedPreferences.getInstance()).getString(AppConstants.prefsJwt);
    return _jwt;
  }

  void setJwt(String token) {
    _jwt = token;
  }

  void clearJwt() {
    _jwt = null;
  }

  Map<String, String> _headers({bool auth = true}) {
    final h = {'Content-Type': 'application/json'};
    if (auth && _jwt != null) h['Authorization'] = 'Bearer $_jwt';
    return h;
  }

  Future<dynamic> post(String path, Map<String, dynamic> body, {bool auth = false}) async {
    if (auth) await _getJwt();
    final uri = Uri.parse('${AppConstants.apiBaseUrl}$path');
    final res = await http.post(uri, headers: _headers(auth: auth), body: jsonEncode(body));
    return _handle(res);
  }

  Future<dynamic> get(String path) async {
    await _getJwt();
    final uri = Uri.parse('${AppConstants.apiBaseUrl}$path');
    final res = await http.get(uri, headers: _headers());
    return _handle(res);
  }

  Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    await _getJwt();
    final uri = Uri.parse('${AppConstants.apiBaseUrl}$path');
    final res = await http.patch(uri, headers: _headers(), body: jsonEncode(body));
    return _handle(res);
  }

  Future<dynamic> postMultipart(
    String path,
    Map<String, String> fields,
    List<http.MultipartFile> files,
  ) async {
    await _getJwt();
    final uri = Uri.parse('${AppConstants.apiBaseUrl}$path');
    final request = http.MultipartRequest('POST', uri);
    if (_jwt != null) request.headers['Authorization'] = 'Bearer $_jwt';
    request.fields.addAll(fields);
    request.files.addAll(files);
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    return _handle(res);
  }

  Future<void> delete(String path) async {
    await _getJwt();
    final uri = Uri.parse('${AppConstants.apiBaseUrl}$path');
    final res = await http.delete(uri, headers: _headers());
    if (res.statusCode == 200 || res.statusCode == 204) return;
    _handle(res);
  }

  dynamic _handle(http.Response res) {
    debugPrint('[API] ${res.request?.method} ${res.request?.url} → ${res.statusCode}');
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      return jsonDecode(res.body);
    }
    String msg;
    try {
      msg = (jsonDecode(res.body) as Map)['error'] ?? res.reasonPhrase ?? 'Error';
    } catch (_) {
      msg = res.reasonPhrase ?? 'Error';
    }
    throw ApiException(res.statusCode, msg);
  }
}
