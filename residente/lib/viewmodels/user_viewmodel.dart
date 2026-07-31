import 'package:flutter/material.dart';

class UserViewModel extends ChangeNotifier {
  String _userName = 'Iván';

  String get userName => _userName;

  void updateUserName(String newName) {
    if (newName.trim().isNotEmpty) {
      _userName = newName.trim();
      notifyListeners(); // Notifica al Dashboard y a Settings del cambio
    }
  }
}