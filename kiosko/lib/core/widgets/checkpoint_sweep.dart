import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:kigo_kiosco/core/theme/kigo_design.dart';

/// Barrido de luz que recorre el recuadro guía de arriba a abajo (y de
/// regreso) mientras se analiza documento/placa/rostro -- el lenguaje visual
/// de un lector de credencial en una caseta, no un overlay decorativo. Se
/// clippea al tamaño del widget padre (usarlo dentro de un `Stack` sobre el
/// recuadro guía, con el mismo tamaño).
class CheckpointSweep extends StatefulWidget {
  final BorderRadius borderRadius;

  const CheckpointSweep({super.key, this.borderRadius = BorderRadius.zero});

  @override
  State<CheckpointSweep> createState() => _CheckpointSweepState();
}

class _CheckpointSweepState extends State<CheckpointSweep> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) => CustomPaint(
            painter: _SweepPainter(t: Curves.easeInOutSine.transform(1 - (2 * _ctrl.value - 1).abs())),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _SweepPainter extends CustomPainter {
  /// 0..1, ya con la curva ida-y-vuelta aplicada -- 0 arriba, 1 abajo.
  final double t;

  _SweepPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * t;
    final grosor = size.height * 0.16;

    final gradient = ui.Gradient.linear(
      Offset(0, y - grosor),
      Offset(0, y + grosor),
      [
        KigoDesign.brand.withValues(alpha: 0),
        KigoDesign.brand.withValues(alpha: 0.55),
        Colors.white,
        KigoDesign.brand.withValues(alpha: 0.55),
        KigoDesign.brand.withValues(alpha: 0),
      ],
      [0.0, 0.35, 0.5, 0.65, 1.0],
    );

    canvas.drawRect(
      Rect.fromLTRB(0, y - grosor, size.width, y + grosor),
      Paint()..shader = gradient,
    );
  }

  @override
  bool shouldRepaint(_SweepPainter oldDelegate) => oldDelegate.t != t;
}
