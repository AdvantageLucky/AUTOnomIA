import 'package:flutter/material.dart';

/// Mismo anillo con resplandor de la pantalla de escaneo, cerrado alrededor
/// de un ícono — el veredicto (concedido/denegado) sigue el mismo lenguaje
/// visual del que viene, en vez de un ícono desconectado.
class VerdictRing extends StatelessWidget {
  final Color color;
  final IconData icon;
  final double size;

  const VerdictRing({super.key, required this.color, required this.icon, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.32), blurRadius: size * 0.32, spreadRadius: size * 0.02),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color, width: 3),
        ),
        child: Icon(icon, color: color, size: size * 0.5),
      ),
    );
  }
}
