import 'package:flutter/material.dart';

class ResidentPinViewModel extends ChangeNotifier {
  String _pin = '';

  String get pin => _pin;
  bool get hasDigits => _pin.isNotEmpty;

  static const int maxLength = 5;

  bool get isComplete => _pin.length == maxLength;

  void addDigit(String digit) {
    if (_pin.length >= maxLength) return;
    _pin += digit;
    notifyListeners();
  }

  void removeLastDigit() {
    if (_pin.isEmpty) return;
    _pin = _pin.substring(0, _pin.length - 1);
    notifyListeners();
  }

  void clear() {
    _pin = '';
    notifyListeners();
  }
}
