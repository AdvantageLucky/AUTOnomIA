import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Adapta el diseño del kiosko —dibujado contra un panel de 800x1280— a la
/// pantalla que le toque: tablets de 7"/10", paneles más grandes, un teléfono
/// durante las pruebas.
///
/// El proyecto tiene la geometría clavada en píxeles lógicos a propósito
/// (`430 son 430 mientras quepan`, ver `qr_scanner_view`): son medidas de
/// diseño pensadas para leerse de pie y a un brazo de distancia, no fracciones
/// del lienzo. Reescribir cada una como porcentaje habría cambiado el diseño
/// en el panel real, así que en vez de eso se escala el lienzo entero:
///
/// * **Escala uniforme.** Todo se dibuja al factor que hace caber el diseño de
///   referencia (`min(ancho/800, alto/1280)`), así que en cualquier pantalla
///   se ve con las mismas proporciones que en el panel — no más chico en una
///   tablet de 10" ni desbordado en una de 7".
/// * **Sin franjas negras.** El eje que sobra no se rellena con barras: se le
///   entrega a la vista como espacio lógico extra. Las pantallas ya lo
///   reparten solas (`Spacer`, `Expanded`, [PantallaAdaptable]).
/// * **Sin estirar de más.** Pasado [_anchoMaximoLogico] el contenido deja de
///   ensancharse y se centra: el kiosko es un diseño vertical y en una tablet
///   apaisada una fila de 2000px de ancho no se lee, se recorre con la vista.
///
/// En el panel de 800x1280 el factor es exactamente 1: no cambia un pixel de
/// lo que ya estaba ajustado ahí.
class LienzoAdaptable extends StatelessWidget {
  const LienzoAdaptable({super.key, required this.child});

  /// El panel para el que está dibujado el kiosko (el F10 en vertical).
  static const double anchoReferencia = 800.0;
  static const double altoReferencia = 1280.0;

  /// Tope de ancho lógico, en múltiplos del de referencia. 1.5 deja que una
  /// pantalla un poco más cuadrada que el panel aproveche el vidrio de más,
  /// y corta antes de que una apaisada convierta cada fila en una tira.
  static const double _anchoMaximoLogico = anchoReferencia * 1.5;

  final Widget child;

  /// Factor con el que se dibuja el diseño en un lienzo dado. Público para
  /// que las pruebas de layout midan contra el mismo número que la app.
  static double escalaPara(Size lienzo) {
    if (lienzo.width <= 0 || lienzo.height <= 0) return 1.0;
    return math.min(
      lienzo.width / anchoReferencia,
      lienzo.height / altoReferencia,
    );
  }

  /// Lienzo lógico que ven las vistas dentro de una pantalla física dada.
  static Size lienzoLogicoPara(Size fisico) {
    final escala = escalaPara(fisico);
    if (escala <= 0) return fisico;
    return Size(
      math.min(fisico.width / escala, _anchoMaximoLogico),
      fisico.height / escala,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final fisico = mq.size;
    if (fisico.isEmpty) return child;

    final escala = escalaPara(fisico);
    final logico = lienzoLogicoPara(fisico);

    // Los recortes del sistema (notch, barra de gestos, teclado) llegan en
    // píxeles físicos: dentro del lienzo escalado valen lo mismo dividido
    // entre el factor, o el `SafeArea` de las pantallas reservaría de más.
    final data = mq.copyWith(
      size: logico,
      padding: mq.padding / escala,
      viewPadding: mq.viewPadding / escala,
      viewInsets: mq.viewInsets / escala,
      systemGestureInsets: mq.systemGestureInsets / escala,
    );

    return ColoredBox(
      // Los márgenes que deja el tope de ancho son parte de la pantalla, no
      // un hueco: van del color del tema, no negros.
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: SizedBox(
          width: logico.width * escala,
          height: logico.height * escala,
          child: FittedBox(
            // Ambos lados se multiplican por el mismo factor, así que `fill`
            // es una escala uniforme -- no deforma nada.
            fit: BoxFit.fill,
            child: SizedBox.fromSize(
              size: logico,
              child: MediaQuery(data: data, child: child),
            ),
          ),
        ),
      ),
    );
  }
}
