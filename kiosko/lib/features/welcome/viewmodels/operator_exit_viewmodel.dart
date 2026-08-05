import 'package:flutter/material.dart';

class OperatorExitViewModel extends ChangeNotifier {
  static const int maxLength = 4;
  static const String _pinOperador = '2026';

  String _pin = '';
  bool _pinIncorrecto = false;

  String get pin => _pin;
  bool get pinIncorrecto => _pinIncorrecto;
  bool get isComplete => _pin.length == maxLength;
  bool get esCorrecto => _pin == _pinOperador;

  void addDigit(String digit) {
    if (_pin.length >= maxLength) return;
    _pinIncorrecto = false;
    _pin += digit;
    notifyListeners();
  }

  void removeLastDigit() {
    if (_pin.isEmpty) return;
    _pinIncorrecto = false;
    _pin = _pin.substring(0, _pin.length - 1);
    notifyListeners();
  }

  void marcarIncorrecto() {
    _pin = '';
    _pinIncorrecto = true;
    notifyListeners();
  }
}
