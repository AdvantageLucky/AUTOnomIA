/* MODELO PARA LOS MOTIVOS DE VISITA (lista fija, no viene de la DB) */
import 'package:flutter/material.dart';

class MotivoVisitaModel {
  final String label;
  final IconData icon;

  const MotivoVisitaModel({required this.label, required this.icon});
}

const List<MotivoVisitaModel> motivosVisita = [
  MotivoVisitaModel(label: 'Paquetería o proveedor', icon: Icons.local_shipping_outlined),
  MotivoVisitaModel(label: 'Visita familiar o social', icon: Icons.people_outline),
  MotivoVisitaModel(label: 'Servicio técnico', icon: Icons.build_outlined),
  MotivoVisitaModel(label: 'Otro', icon: Icons.more_horiz),
];
