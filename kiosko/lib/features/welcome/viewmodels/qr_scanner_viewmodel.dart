import 'package:flutter/material.dart';

class QrScannerViewModel extends ChangeNotifier {
  bool _isScanned = false;
  String? _scannedValue;

  bool get isScanned => _isScanned;
  String? get scannedValue => _scannedValue;

  void onQrDetected(String value) {
    if (_isScanned) return;
    _isScanned = true;
    _scannedValue = value;
    notifyListeners();
  }

  void reset() {
    _isScanned = false;
    _scannedValue = null;
    notifyListeners();
  }
}
