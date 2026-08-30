import 'package:flutter/material.dart';

/// Envuelve cualquier widget para darle feedback visual de presión (escala
/// hacia abajo) sin que cada botón tenga que manejar su propio color de
/// estado — a diferencia del patrón `_presionadoId` + `AnimatedContainer`
/// que ya usan algunos botones de esta app, este funciona igual sin
/// importar la forma o el color de lo que envuelve.
class Presionable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double escalaPresionado;

  const Presionable({
    super.key,
    required this.child,
    this.onTap,
    this.escalaPresionado = 0.94,
  });

  @override
  State<Presionable> createState() => _PresionableState();
}

class _PresionableState extends State<Presionable> {
  bool _presionado = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _presionado = true),
      onTapUp: (_) {
        setState(() => _presionado = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _presionado = false),
      child: AnimatedScale(
        scale: _presionado ? widget.escalaPresionado : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
