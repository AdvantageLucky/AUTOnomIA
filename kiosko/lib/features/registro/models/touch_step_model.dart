/* MODELO PARA LOS PASOS DEL REGISTRO TÁCTIL */
import 'package:flutter/material.dart';

class TouchStepModel {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final String buttonText;

  TouchStepModel({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.buttonText,
  });
}