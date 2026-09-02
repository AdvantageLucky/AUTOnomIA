import 'package:flutter/material.dart';

/// Badge cuadrado de marca -- antes una "K" blanca sobre un cuadro naranja,
/// repetida casi idéntica en ~8 pantallas. Ahora es el isotipo real de
/// AUTOnomIA (mismo archivo que el ícono de kigo-app), un solo widget en vez
/// de duplicar Container+Text('K') en cada header.
class MarcaBadge extends StatelessWidget {
  final double lado;

  const MarcaBadge({super.key, this.lado = 48});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(lado * 0.29),
      child: Image.asset(
        'assets/icon/marca_autonomia.jpg',
        width: lado,
        height: lado,
        fit: BoxFit.cover,
      ),
    );
  }
}
