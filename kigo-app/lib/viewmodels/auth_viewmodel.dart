import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/membresia_model.dart';
import '../services/api_service.dart';
import '../services/push_service.dart';
import '../utils/constants.dart';

enum MembresiaEstado { ninguna, pendiente, rechazada, activa }

/// Identidad de la app: Persona (teléfono+OTP), no Residente. Ver spec
/// 2026-08-17-kigo-app-rediseno-design.md §4.
class AuthViewModel extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = false;
  bool _isInitializing = true;
  String? _error;

  String _telefono = '';
  String _nombre = '';
  String _apellidoPaterno = '';
  String _apellidoMaterno = '';

  MembresiaActual? _membresia;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;
  String? get error => _error;
  String get telefono => _telefono;
  String get nombre => _nombre;
  String get apellidoPaterno => _apellidoPaterno;
  String get apellidoMaterno => _apellidoMaterno;
  String get nombreCompleto => '$_nombre $_apellidoPaterno'.trim();
  bool get perfilCompleto => _nombre.isNotEmpty;
  MembresiaActual? get membresia => _membresia;

  MembresiaEstado get membresiaEstado {
    if (_membresia == null) return MembresiaEstado.ninguna;
    switch (_membresia!.status) {
      case 'activo':
        return MembresiaEstado.activa;
      case 'rechazado':
        return MembresiaEstado.rechazada;
      default:
        return MembresiaEstado.pendiente;
    }
  }

  late final Future<void> _readyFuture;

  /// Resuelve cuando `_checkSession` terminó (con o sin sesión) — usado
  /// por SplashView para esperar de verdad antes de decidir la ruta.
  Future<void> waitUntilReady() => _readyFuture;

  AuthViewModel() {
    _readyFuture = _checkSession();
  }

  Future<void> _checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString(AppConstants.prefsJwt);
    if (jwt == null) {
      _isInitializing = false;
      notifyListeners();
      return;
    }

    ApiService().setJwt(jwt);
    try {
      await _cargarPerfilYMembresia();
      _isAuthenticated = true;
      PushService().iniciar(); // fire-and-forget, no bloquea el arranque
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        // sesión realmente inválida o expirada
        await logout();
      }
      // otro error del servidor — no se borra el JWT, se deja
      // _isAuthenticated en false para que el usuario reintente
    } catch (_) {
      // error de red/timeout — no se borra el JWT, se deja
      // _isAuthenticated en false; la próxima apertura reintenta
    }
    _isInitializing = false;
    notifyListeners();
  }

  /// Paso 1 del onboarding: pide el código OTP para un teléfono. [correo] es
  /// opcional — si viene, el backend manda el código por correo en vez de
  /// SMS (mientras no haya un proveedor de SMS real configurado); el
  /// teléfono sigue siendo el ancla de identidad de la Persona.
  Future<void> solicitarOtp(String telefono, {String? correo}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await ApiService().post('/personas/registro/solicitar-otp', {
        'telefono': telefono,
        if (correo != null && correo.isNotEmpty) 'correo': correo,
      });
      _telefono = telefono;
      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      rethrow;
    } catch (e) {
      _error = 'No se pudo conectar al servidor';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Paso 2: verifica el código y establece la sesión.
  Future<void> verificarOtp(String codigo) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await ApiService().post('/personas/registro/verificar-otp', {
        'telefono': _telefono,
        'codigo': codigo,
      });
      final jwt = data['access_token'] as String;
      ApiService().setJwt(jwt);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.prefsJwt, jwt);

      await _cargarPerfilYMembresia();
      _isAuthenticated = true;
      _isLoading = false;
      PushService().iniciar(); // fire-and-forget, no bloquea el login
      notifyListeners();
    } on ApiException catch (e) {
      await _revertirJwtParcial();
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      rethrow;
    } catch (e) {
      await _revertirJwtParcial();
      _error = 'No se pudo conectar al servidor';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _revertirJwtParcial() async {
    ApiService().clearJwt();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.prefsJwt);
  }

  /// Paso 3 (solo si `perfilCompleto` es false tras verificar): wizard de
  /// identidad — INE + rostro, ver spec §10. Une nombre/apellidos/CURP
  /// confirmados + ambas fotos + embedding facial en una sola llamada.
  Future<void> completarIdentidad({
    required String nombre,
    required String apellidoPaterno,
    required String apellidoMaterno,
    required String curp,
    required String pathFotoIne,
    required String pathFotoRostro,
    required List<double> embedding,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await ApiService().postMultipart(
        '/personas/me/identidad',
        {
          'nombre': nombre,
          'apellido_paterno': apellidoPaterno,
          'apellido_materno': apellidoMaterno,
          'curp': curp,
          'embedding': jsonEncode(embedding),
        },
        [
          await http.MultipartFile.fromPath(
            'foto_documento',
            pathFotoIne,
            contentType: MediaType('image', 'jpeg'),
          ),
          await http.MultipartFile.fromPath(
            'foto_rostro',
            pathFotoRostro,
            contentType: MediaType('image', 'jpeg'),
          ),
        ],
      );
      _nombre = data['nombre'] as String;
      _apellidoPaterno = data['apellido_paterno'] as String;
      _apellidoMaterno = data['apellido_materno'] as String;
      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      rethrow;
    } catch (e) {
      _error = 'No se pudo conectar al servidor';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Paso 4: une la Persona a un centro — queda pendiente de aprobación.
  Future<void> unirseCentro(String codigoCentro, String casaDestino, String pin) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await ApiService().post(
        '/personas/me/membresias',
        {'codigo_centro': codigoCentro, 'casa_destino': casaDestino, 'pin': pin},
        auth: true,
      );
      await _cargarMembresia();
      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      rethrow;
    } catch (e) {
      _error = 'No se pudo conectar al servidor';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Recarga el estado de la Membresia — usado por la pantalla de espera
  /// para consultar si el admin ya aprobó.
  Future<void> refrescarMembresia() async {
    try {
      await _cargarMembresia();
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    } catch (e) {
      _error = 'No se pudo conectar al servidor';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _cargarPerfilYMembresia() async {
    final perfil = await ApiService().get('/personas/me');
    _nombre = perfil['nombre'] as String;
    _apellidoPaterno = perfil['apellido_paterno'] as String;
    _apellidoMaterno = perfil['apellido_materno'] as String;
    await _cargarMembresia();
  }

  Future<void> _cargarMembresia() async {
    final data = await ApiService().get('/personas/me/membresias');
    final list = (data['membresias'] as List).cast<Map<String, dynamic>>();
    _membresia = list.isEmpty ? null : MembresiaActual.fromJson(list.first);
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _telefono = '';
    _nombre = '';
    _apellidoPaterno = '';
    _apellidoMaterno = '';
    _membresia = null;
    _error = null;
    ApiService().clearJwt();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.prefsJwt);
    notifyListeners();
  }
}
