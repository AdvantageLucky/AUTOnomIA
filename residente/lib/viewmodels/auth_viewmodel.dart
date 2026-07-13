import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthViewModel extends ChangeNotifier {
  bool _isAuthenticated = false;
  String _currentUserName = '';
  String _userPin = '';
  bool _rememberMe = false;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoggedIn => _isAuthenticated; 
  String get currentUserName => _currentUserName;
  String get userPin => _userPin;
  bool get rememberMe => _rememberMe;

  static const String _pinStorageKey = 'kigo_user_pin';
  static const String _sessionKey = 'kigo_session_active';
  static const String _rememberMeKey = 'kigo_remember_me';

  AuthViewModel() {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    _userPin = prefs.getString(_pinStorageKey) ?? '';
    _rememberMe = prefs.getBool(_rememberMeKey) ?? false;
    notifyListeners();
  }

  Future<void> checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final bool sessionActive = prefs.getBool(_sessionKey) ?? false;
    final bool remember = prefs.getBool(_rememberMeKey) ?? false;

    if (sessionActive && remember) {
      _isAuthenticated = true;
      _currentUserName = 'Iván';
    } else {
      _isAuthenticated = false;
    }
    notifyListeners();
  }

  void toggleRememberMe([bool? value]) {
    _rememberMe = value ?? !_rememberMe;
    _saveRememberMeOption();
    notifyListeners();
  }

  Future<void> _saveRememberMeOption() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeKey, _rememberMe);
  }

  Future<bool> login(String email, String password) async {
    if (email == 'ivan@kigo.com' || email.contains('ivan')) {
      _isAuthenticated = true;
      _currentUserName = 'Iván';
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_sessionKey, true);

      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    _isAuthenticated = false;
    _currentUserName = '';
    
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool(_sessionKey, false);
    });

    notifyListeners();
  }

  // ESTE ES EL MÉTODO QUE BUSCA EL DASHBOARD
  Future<String> generateUniquePin() async {
    if (_userPin.isNotEmpty) return _userPin;

    final random = Random();
    String newPin;
    bool isUnique = false;

    final List<String> existingUserPins = ['12345', '54321', '00000', '99999'];

    do {
      int number = 10000 + random.nextInt(90000);
      newPin = number.toString();
      
      if (!existingUserPins.contains(newPin)) {
        isUnique = true;
      }
    } while (!isUnique);

    _userPin = newPin;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinStorageKey, _userPin);
    
    notifyListeners();
    return _userPin;
  }
}