import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class AuthViewModel extends ChangeNotifier {
  bool _isAuthenticated = false;
  String _nombre = '';
  String _casaDestino = '';
  int _kioskoId = 0;
  int? _destinoId;
  bool _isLoading = false;
  String? _error;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoggedIn => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get nombre => _nombre;
  String get casaDestino => _casaDestino;
  int get kioskoId => _kioskoId;
  int? get destinoId => _destinoId;

  AuthViewModel() {
    _checkSession();
  }

  Future<void> _checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString(AppConstants.prefsJwt);
    if (jwt == null) return;

    ApiService().setJwt(jwt);
    _nombre = prefs.getString(AppConstants.prefsNombre) ?? '';
    _casaDestino = prefs.getString(AppConstants.prefsCasaDestino) ?? '';
    _kioskoId = prefs.getInt(AppConstants.prefsKioskoId) ?? 0;
    _destinoId = prefs.getInt(AppConstants.prefsDestinoId);
    _isAuthenticated = true;
    notifyListeners();
  }

  Future<bool> login(String codigoInstalacion, String casaDestino, String pin) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await ApiService().post(
        '/centros/${codigoInstalacion.trim().toUpperCase()}/residentes/login',
        {
          'casa_destino': casaDestino,
          'pin': pin,
        },
      );

      final jwt = data['access_token'] as String;
      ApiService().setJwt(jwt);

      // Cargar perfil para obtener nombre y destino_id
      final perfil = await ApiService().get('/residentes/me');
      _nombre = '${perfil['nombre']} ${perfil['apellido_paterno']}';
      _casaDestino = perfil['casa_destino'] as String;
      _kioskoId = (perfil['kiosko_id'] as int?) ?? 0;
      _destinoId = perfil['destino_id'] as int?;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.prefsJwt, jwt);
      await prefs.setString(AppConstants.prefsNombre, _nombre);
      await prefs.setString(AppConstants.prefsCasaDestino, _casaDestino);
      await prefs.setInt(AppConstants.prefsKioskoId, _kioskoId);
      if (_destinoId != null) await prefs.setInt(AppConstants.prefsDestinoId, _destinoId!);

      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'No se pudo conectar al servidor';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _nombre = '';
    _casaDestino = '';
    _kioskoId = 0;
    _destinoId = null;
    ApiService().clearJwt();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.prefsJwt);
    await prefs.remove(AppConstants.prefsNombre);
    await prefs.remove(AppConstants.prefsCasaDestino);
    await prefs.remove(AppConstants.prefsKioskoId);
    await prefs.remove(AppConstants.prefsDestinoId);
    notifyListeners();
  }
}
