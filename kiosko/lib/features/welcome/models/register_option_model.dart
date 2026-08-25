/* MODELO DE OPCIONES DE REGISTRO */
import 'package:flutter/material.dart';

class RegisterOptionModel {
  final String id;

  /// Clave de l10n para el título — el ViewModel no tiene BuildContext, así
  /// que la vista resuelve el texto en render con AppLocalizations.t(context, titleKey).
  final String titleKey;
  final String subtitle;
  final IconData icon;

  RegisterOptionModel({
    required this.id,
    required this.titleKey,
    required this.subtitle,
    required this.icon,
  });
}