import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsViewModel extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
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

    // Cargar tema
    final isDark = prefs.getBool('is_dark_mode') ?? true;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;

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