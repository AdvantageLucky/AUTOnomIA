import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/membresia_model.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

enum MembresiaEstado { ninguna, pendiente, activa }

/// Identidad de la app: Persona (teléfono+OTP), no Residente. Ver spec
/// 2026-08-17-kigo-app-rediseno-design.md §4.
class AuthViewModel extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;

  String _telefono = '';
  String _nombre = '';
  String _apellidoPaterno = '';
  String _apellidoMaterno = '';

  MembresiaActual? _membresia;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
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
    return _membresia!.status == 'activo' ? MembresiaEstado.activa : MembresiaEstado.pendiente;
  }

  AuthViewModel() {
    _checkSession();
  }

  Future<void> _checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString(AppConstants.prefsJwt);
    if (jwt == null) return;

    ApiService().setJwt(jwt);
    try {
      await _cargarPerfilYMembresia();
      _isAuthenticated = true;
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
    notifyListeners();
  }

  /// Paso 1 del onboarding: pide el código OTP para un teléfono.
  Future<void> solicitarOtp(String telefono) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await ApiService().post('/personas/registro/solicitar-otp', {'telefono': telefono});
      _telefono = telefono;
      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
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
      notifyListeners();
    } on ApiException catch (e) {
      ApiService().clearJwt();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.prefsJwt);
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Paso 3 (solo si `perfilCompleto` es false tras verificar): completa
  /// nombre/apellidos de una Persona nueva.
  Future<void> completarPerfil(String nombre, String apellidoPaterno, String apellidoMaterno) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await ApiService().patch('/personas/me', {
        'nombre': nombre,
        'apellido_paterno': apellidoPaterno,
        'apellido_materno': apellidoMaterno,
      });
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
    ApiService().clearJwt();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.prefsJwt);
    notifyListeners();
  }
}
