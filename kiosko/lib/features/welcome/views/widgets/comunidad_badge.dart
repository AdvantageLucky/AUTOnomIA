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

/// Las medidas de la pastilla, en un solo lugar: las usa tanto el widget al
/// dibujarse como [altoPastillaComunidad] al medirla sin montarla. Si se
/// separan, quien la coloca en un `Stack` calcula un alto que no es el real.
///
/// El cromo de los lados deja de crecer con la escala. La pastilla del
/// escaneo va a x3 y de ancho completo: ahi 22*e daban 66px de padding por
/// lado y 10*e otros 30 de separacion contra cada punto, 192 de los 776 de
/// ancho que no eran texto. El mensaje del panel mide 625 en un renglon, no
/// le quedaban mas que 541 y se partia en dos -- la pastilla salia corta y
/// alta, y era ese alto de mas el que la subia contra la mascota del
/// asistente. Con el tope le quedan 650 y entra de largo, que es como tiene
/// que leerse. El padding vertical y el borde si siguen a la escala: son los
/// que le dan cuerpo.
double _padH(double e) => math.min(22 * e, 29.0);
double _separacion(double e) => math.min(10 * e, 13.0);
double _padV(double e) => 10 * e;
double _borde(double e) => 1.2 * e;
double _ladoPunto(double e) => 6 * e;

TextStyle _estiloMensaje(double e, bool envolverTexto) => TextStyle(
      color: KigoDesign.brandHover,
      fontSize: 16 * e,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.3 * e,
      height: envolverTexto ? 1.25 : null,
    );

/// Alto que va a ocupar la pastilla para un mensaje y un ancho dados, sin
/// montarla.
///
/// Lo necesita la pantalla de escaneo: ahi el recuadro del QR va en un
/// `Stack` y su posicion se calcula antes del layout, asi que para colgarlo
/// de la pastilla hay que saber cuanto mide *antes* de dibujarla. Cuantos
/// renglones ocupa el mensaje depende de la fuente real, y por eso se mide
/// con un `TextPainter` con el mismo estilo (heredado del tema incluido) en
/// vez de estimarlo.
double altoPastillaComunidad(
  BuildContext context, {
  required String mensaje,
  required double ancho,
  double escala = 1,
  bool envolverTexto = false,
}) {
  if (mensaje.isEmpty) return 0;

  final e = escala;
  // Lo que le queda al texto: el ancho menos todo el cromo de los lados
  // (borde, padding, el punto y su separacion) por duplicado.
  final anchoTexto = ancho -
      2 * (_borde(e) + _padH(e) + _ladoPunto(e) + _separacion(e));

  final pintor = TextPainter(
    text: TextSpan(
      text: mensaje,
      // El estilo base es el del tema y no `DefaultTextStyle.of(context)`:
      // quien mide lo hace desde el `build` de la pantalla, que está POR
      // ENCIMA del `Material` del Scaffold -- ahí el default sigue siendo el
      // de arranque de WidgetsApp (monospace) y no la tipografía real, y el
      // mensaje del panel salía en dos renglones en vez de uno.
      style: (Theme.of(context).textTheme.bodyMedium ?? const TextStyle())
          .merge(_estiloMensaje(e, envolverTexto)),
    ),
    textAlign: TextAlign.center,
    textDirection: Directionality.of(context),
    maxLines: envolverTexto ? null : 1,
    textScaler: MediaQuery.textScalerOf(context),
  )..layout(maxWidth: math.max(anchoTexto, 0));
  final altoTexto = pintor.height;
  pintor.dispose();

  // El `Row` mide lo que el mas alto de sus hijos -- el texto o el punto --
  // y encima van el padding vertical y el borde de la caja.
  return math.max(altoTexto, _ladoPunto(e)) + 2 * (_padV(e) + _borde(e));
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
    final padH = _padH(e);
    final separacion = _separacion(e);

    return AnimatedBuilder(
      animation: _shimmerCtrl,
      builder: (_, child) {
        final angle = _shimmerCtrl.value * 2 * math.pi;
        return Container(
          padding: EdgeInsets.symmetric(horizontal: padH, vertical: _padV(e)),
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
              width: _borde(e),
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
              style: _estiloMensaje(e, widget.envolverTexto),
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
        width: _ladoPunto(e),
        height: _ladoPunto(e),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: KigoDesign.brand,
        ),
      );
}
