/* MODELO PARA LOS PASOS DEL REGISTRO TÁCTIL */
import 'package:flutter/material.dart';

class TouchStepModel {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  // Clave de AppLocalizations, no el texto ya resuelto — este modelo lo arma
  // el ViewModel, que no tiene BuildContext; la vista resuelve la clave al
  // idioma activo en el momento de dibujar el botón.
  final String buttonTextKey;

  TouchStepModel({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.buttonTextKey,
  });
}