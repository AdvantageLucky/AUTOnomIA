/* VIEWMODEL PARA LA PANTALLA DE BIENVENIDA */
import 'package:flutter/material.dart';
import 'package:kigo_kiosco/features/welcome/models/register_option_model.dart';

class WelcomeViewModel extends ChangeNotifier {
  String? selectedOptionId;

  final List<RegisterOptionModel> options = [
    RegisterOptionModel(
      id: 'residente',
      titleKey: 'residente_label',
      subtitle: '',
      icon: Icons.home_rounded,
    ),
    RegisterOptionModel(
      id: 'visitante',
      titleKey: 'visitante_label',
      subtitle: '',
      icon: Icons.person_rounded,
    ),
  ];

  void selectOption(String id) {
    selectedOptionId = id;
    notifyListeners();
  }

  bool isSelected(String id) {
    return selectedOptionId == id;
  }
}