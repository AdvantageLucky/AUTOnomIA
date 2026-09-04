import 'package:flutter/material.dart';
import 'package:kigo_salida/core/theme/kigo_design.dart';
import 'package:kigo_salida/core/widgets/checkpoint_sweep.dart';

/// Overlay de cámara con un recorte guía (óvalo) -- mismo tratamiento
/// visual que kiosko/lib/core/widgets/marco_guia_camara.dart, copiado tal
/// cual para mantener el mismo estilo entre las dos apps.
class MarcoGuiaCamara extends StatelessWidget {
  final double ancho;
  final double alto;
  final Color? colorBorde;
  final bool mostrarBarrido;

  const MarcoGuiaCamara({
    super.key,
    required this.ancho,
    required this.alto,
    this.colorBorde,
    this.mostrarBarrido = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _OverlayOpacoPainter(ancho, alto, context.kBg),
          ),
        ),
        if (mostrarBarrido)
          Center(
            child: SizedBox(
              width: ancho,
              height: alto,
              child: ClipOval(child: CheckpointSweep()),
            ),
          ),
        Center(
          child: SizedBox(
            width: ancho,
            height: alto,
            child: CustomPaint(painter: _GuiaPainter(colorBorde ?? KigoDesign.brand)),
          ),
        ),
      ],
    );
  }
}

class _OverlayOpacoPainter extends CustomPainter {
  final double ancho;
  final double alto;
  final Color colorVelo;

  _OverlayOpacoPainter(this.ancho, this.alto, this.colorVelo);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = colorVelo;
    final full = Rect.fromLTWH(0, 0, size.width, size.height);
    final cx = size.width / 2;
    final cy = size.height / 2;
    final recorte = Rect.fromCenter(center: Offset(cx, cy), width: ancho, height: alto);
    final path = Path()
      ..addRect(full)
      ..addOval(recorte)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _OverlayOpacoPainter oldDelegate) =>
      oldDelegate.ancho != ancho || oldDelegate.alto != alto || oldDelegate.colorVelo != colorVelo;
}

class _GuiaPainter extends CustomPainter {
  final Color color;
  const _GuiaPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    final rect = Offset.zero & size;
    canvas.drawOval(rect.deflate(1.5), paint);
  }

  @override
  bool shouldRepaint(covariant _GuiaPainter oldDelegate) => oldDelegate.color != color;
}
