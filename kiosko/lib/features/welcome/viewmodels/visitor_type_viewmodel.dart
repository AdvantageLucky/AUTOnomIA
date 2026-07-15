import 'package:flutter/material.dart';
import 'package:kigo_kiosco/features/welcome/models/register_option_model.dart';

class VisitorTypeViewModel extends ChangeNotifier {
  String? selectedOptionId;

  final List<RegisterOptionModel> options = [
    RegisterOptionModel(
      id: 'tengo_invitacion',
      title: 'Escanear invitación',
      subtitle: '',
      icon: Icons.qr_code_scanner_rounded,
    ),
    RegisterOptionModel(
      id: 'soy_visitante',
      title: 'No tengo invitación',
      subtitle: '',
      icon: Icons.badge_rounded,
    ),
  ];

  void selectOption(String id) {
    selectedOptionId = id;
    notifyListeners();
  }

  bool isSelected(String id) => selectedOptionId == id;
}
