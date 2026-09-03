import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsViewModel extends ChangeNotifier {
  // Sigue el tema del sistema (día/noche) mientras el usuario no elija uno
  // a mano en Ajustes -- antes arrancaba fijo en oscuro sin importar el
  // modo del teléfono, incluso en la primerísima pantalla de onboarding.
  ThemeMode _themeMode = ThemeMode.system;
  Locale _currentLocale = const Locale('es');
  String _userName = 'Iván';

  ThemeMode get themeMode => _themeMode;
  Locale get currentLocale => _currentLocale;
  String get userName => _userName;

  SettingsViewModel() {
    _loadPreferences();
  }

  // Cargar preferencias guardadas al iniciar la app
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Cargar idioma
    final languageCode = prefs.getString('language_code') ?? 'es';
    _currentLocale = Locale(languageCode);

    // Cargar tema -- si nunca se tocó el switch de Ajustes, no hay
    // preferencia explícita que respetar: se sigue el modo del sistema. Solo
    // una vez que el usuario elige a mano queda fijo en claro/oscuro.
    if (prefs.containsKey('is_dark_mode')) {
      final isDark = prefs.getBool('is_dark_mode')!;
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system;
    }

    // Cargar nombre de usuario
    _userName = prefs.getString('user_name') ?? 'Iván';

    notifyListeners();
  }

  // Cambiar y guardar idioma
  Future<void> changeLanguage(String languageCode) async {
    _currentLocale = Locale(languageCode);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', languageCode);
  }

  // Cambiar y guardar tema
  Future<void> toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', isDark);
  }

  // Cambiar y guardar nombre de usuario
  Future<void> updateUserName(String newName) async {
    if (newName.trim().isNotEmpty) {
      _userName = newName.trim();
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', _userName);
    }
  }
}