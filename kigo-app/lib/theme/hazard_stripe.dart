import 'package:flutter/material.dart';
import 'package:kigo_user/theme/app_theme.dart';

/// Franja diagonal naranja/negro — mismo motivo que `HazardStripeBar` del
/// kiosko (tomado de una caseta de vialidad, no del vocabulario decorativo
/// típico de un dashboard de IA). Se duplica aquí porque kigo-app y kiosko
/// son paquetes Flutter independientes sin un módulo compartido.
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
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = AppTheme.backgroundBlack);

    final paint = Paint()..color = AppTheme.primaryOrange;
    final corrido = desplazamiento * _anchoFranja * 2;
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
