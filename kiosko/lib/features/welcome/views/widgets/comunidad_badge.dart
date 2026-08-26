import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kigo_kiosco/core/theme/kigo_design.dart';

/// Pastilla con el nombre de la comunidad — el `mensaje_bienvenida` que se
/// escribe en el dashboard.
///
/// El degradado gira despacio: es lo único vivo en pantalla mientras nadie se
/// para frente al kiosko. La comparten la bienvenida y el escaneo para que el
/// visitante lea lo mismo, igual, en las dos.
class ComunidadBadge extends StatefulWidget {
  final String mensaje;

  /// Multiplica la pastilla completa. La bienvenida la deja en 1; la pantalla
  /// de escaneo la sube, porque ahí el mensaje es lo único que acompaña al
  /// recuadro sobre el fondo negro.
  final double escala;

  const ComunidadBadge({
    super.key,
    required this.mensaje,
    this.escala = 1,
  });

  @override
  State<ComunidadBadge> createState() => _ComunidadBadgeState();
}

class _ComunidadBadgeState extends State<ComunidadBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.escala;

    return AnimatedBuilder(
      animation: _shimmerCtrl,
      builder: (_, child) {
        final angle = _shimmerCtrl.value * 2 * math.pi;
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 22 * e, vertical: 10 * e),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40 * e),
            gradient: LinearGradient(
              begin: Alignment(math.cos(angle), math.sin(angle)),
              end: Alignment(-math.cos(angle), -math.sin(angle)),
              colors: [
                KigoDesign.brand.withValues(alpha: 0.13),
                KigoDesign.brand.withValues(alpha: 0.04),
                KigoDesign.brand.withValues(alpha: 0.13),
              ],
            ),
            border: Border.all(
              color: KigoDesign.brand.withValues(alpha: 0.3),
              width: 1.2 * e,
            ),
          ),
          child: child,
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _punto(e),
          SizedBox(width: 10 * e),
          Flexible(
            child: Text(
              widget.mensaje,
              style: TextStyle(
                color: KigoDesign.brandHover,
                fontSize: 16 * e,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3 * e,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 10 * e),
          _punto(e),
        ],
      ),
    );
  }

  Widget _punto(double e) => Container(
        width: 6 * e,
        height: 6 * e,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: KigoDesign.brand,
        ),
      );
}
