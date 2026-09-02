import 'package:flutter/material.dart';
import 'package:kigo_kiosco/core/theme/kigo_design.dart';

/// Franja diagonal naranja/negro — el motivo tomado literalmente de una
/// caseta de vialidad (cono, pluma, chaleco), no del vocabulario decorativo
/// típico de un dashboard de IA. Se usa con moderación: barra de progreso de
/// verificación y esquina de tarjetas en estado pendiente/alerta.
class HazardStripeBar extends StatefulWidget {
  final double height;
  final BorderRadius? borderRadius;

  const HazardStripeBar({super.key, this.height = 6, this.borderRadius});

  @override
  State<HazardStripeBar> createState() => _HazardStripeBarState();
}

class _HazardStripeBarState extends State<HazardStripeBar> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.circular(widget.height / 2),
      child: SizedBox(
        height: widget.height,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) => CustomPaint(
            painter: _HazardStripePainter(desplazamiento: _ctrl.value),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _HazardStripePainter extends CustomPainter {
  final double desplazamiento;
  static const _anchoFranja = 14.0;

  _HazardStripePainter({required this.desplazamiento});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = KigoDesign.bgDark);

    final paint = Paint()..color = KigoDesign.brand;
    final corrido = desplazamiento * _anchoFranja * 2;
    // Franjas a 45°: se dibujan como paralelogramos que se recorren en bucle
    // hacia la derecha -- la misma lectura visual de una pluma de caseta.
    for (var x = -size.height - corrido; x < size.width + _anchoFranja; x += _anchoFranja * 2) {
      final path = Path()
        ..moveTo(x, size.height)
        ..lineTo(x + size.height, 0)
        ..lineTo(x + size.height + _anchoFranja, 0)
        ..lineTo(x + _anchoFranja, size.height)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_HazardStripePainter oldDelegate) => oldDelegate.desplazamiento != desplazamiento;
}
