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
  /// recuadro sobre el fondo de la pantalla.
  final double escala;

  /// Qué hacer cuando el nombre no cabe en un renglón. `false` lo corta con
  /// puntos suspensivos; `true` lo pasa al siguiente renglón, que es lo que
  /// quiere la pantalla de escaneo: ahí el nombre del fraccionamiento es la
  /// única pista de dónde está parado el visitante y tiene que leerse entero.
  final bool envolverTexto;

  const ComunidadBadge({
    super.key,
    required this.mensaje,
    this.escala = 1,
    this.envolverTexto = false,
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
    // El cromo de los lados deja de crecer con la escala. La pastilla del
    // escaneo va a x3 y de ancho completo: ahi 22*e daban 66px de padding por
    // lado y 10*e otros 30 de separacion contra cada punto, 192 de los 776 de
    // ancho que no eran texto. El mensaje del panel mide 625 en un renglon,
    // no le quedaban mas que 541 y se partia en dos -- la pastilla salia
    // corta y alta, y era ese alto de mas el que la subia contra la mascota
    // del asistente. Con el tope le quedan 650 y entra de largo, que es como
    // tiene que leerse. El padding vertical y el borde si siguen a la escala:
    // son los que le dan cuerpo.
    final padH = math.min(22 * e, 29.0);
    final separacion = math.min(10 * e, 13.0);

    return AnimatedBuilder(
      animation: _shimmerCtrl,
      builder: (_, child) {
        final angle = _shimmerCtrl.value * 2 * math.pi;
        return Container(
          padding: EdgeInsets.symmetric(horizontal: padH, vertical: 10 * e),
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
          SizedBox(width: separacion),
          Flexible(
            child: Text(
              widget.mensaje,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: KigoDesign.brandHover,
                fontSize: 16 * e,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3 * e,
                height: widget.envolverTexto ? 1.25 : null,
              ),
              // Sin tope de renglones no hay nada que recortar: el texto crece
              // hacia abajo y, si la pastilla ya no cabe en su hueco, el
              // FittedBox de quien la monta la escala.
              maxLines: widget.envolverTexto ? null : 1,
              overflow: widget.envolverTexto
                  ? TextOverflow.clip
                  : TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: separacion),
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
