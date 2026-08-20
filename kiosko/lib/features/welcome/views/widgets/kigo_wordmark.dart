import 'package:flutter/material.dart';
import 'package:kigo_kiosco/core/theme/kigo_design.dart';

/// Marca mínima de esquina — reemplaza el lockup grande "Kigo / SELF
/// CHECK-IN" repetido en cada pantalla del flujo QR. El veredicto de cada
/// pantalla (escaneando / acceso concedido / denegado) es el protagonista;
/// esto solo confirma en qué app estás, en voz baja.
class KigoWordmark extends StatelessWidget {
  final Color color;
  const KigoWordmark({super.key, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: KigoDesign.brand,
            borderRadius: BorderRadius.circular(7),
          ),
          child: const Center(
            child: Text(
              'K',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Kigo',
          style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.2),
        ),
      ],
    );
  }
}
