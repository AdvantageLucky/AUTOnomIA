// El kiosko está dibujado contra un panel de 800x1280 y LienzoAdaptable es
// lo que hace que ese diseño sirva en otra pantalla. Lo que se fija aquí:
//
// * en el panel de referencia no toca nada (factor 1, mismo lienzo),
// * en cualquier otra pantalla las vistas siguen recibiendo al menos el
//   lienzo de referencia -- nunca menos ancho ni menos alto del que se
//   diseñaron,
// * el diseño se dibuja del tamaño de la pantalla, sin franjas en el eje que
//   ajusta, y
// * los recortes del sistema llegan convertidos a la escala del lienzo.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kigo_kiosco/core/widgets/lienzo_adaptable.dart';

const _lienzos = <String, Size>{
  'panel 800x1280': Size(800, 1280),
  'tablet 7" vertical': Size(600, 1024),
  'tablet 10" horizontal': Size(1280, 800),
  'panel grande': Size(1200, 1920),
  'telefono': Size(411, 891),
  'telefono chico': Size(320, 640),
};

/// Monta el lienzo y devuelve lo que ve la pantalla de adentro.
Future<({Size logico, EdgeInsets padding, Rect dibujado})> _montar(
  WidgetTester tester,
  Size fisico, {
  FakeViewPadding recortes = FakeViewPadding.zero,
}) async {
  tester.view.physicalSize = fisico;
  tester.view.devicePixelRatio = 1.0;
  tester.view.padding = recortes;
  tester.view.viewPadding = recortes;
  addTearDown(tester.view.reset);

  late Size logico;
  late EdgeInsets padding;
  const clave = ValueKey('adentro');

  await tester.pumpWidget(MaterialApp(
    builder: (context, child) => LienzoAdaptable(child: child!),
    home: Builder(builder: (context) {
      logico = MediaQuery.sizeOf(context);
      padding = MediaQuery.paddingOf(context);
      return const SizedBox.expand(child: ColoredBox(key: clave, color: Colors.red));
    }),
  ));

  return (
    logico: logico,
    padding: padding,
    dibujado: tester.getRect(find.byKey(clave)),
  );
}

void main() {
  testWidgets('en el panel de referencia no cambia nada', (tester) async {
    final r = await _montar(tester, const Size(800, 1280));

    expect(r.logico, const Size(800, 1280));
    expect(LienzoAdaptable.escalaPara(const Size(800, 1280)), 1.0);
    expect(r.dibujado, const Rect.fromLTWH(0, 0, 800, 1280));
  });

  _lienzos.forEach((etiqueta, fisico) {
    testWidgets('la vista nunca recibe menos que el diseño en $etiqueta',
        (tester) async {
      final r = await _montar(tester, fisico);

      // Ni más angosto ni más bajo que el panel: si lo fuera, el contenido
      // que cabe en el kiosko real no cabría aquí.
      expect(r.logico.width, greaterThanOrEqualTo(LienzoAdaptable.anchoReferencia - 0.01));
      expect(r.logico.height, greaterThanOrEqualTo(LienzoAdaptable.altoReferencia - 0.01));
    });

    testWidgets('el diseño llena la pantalla en $etiqueta', (tester) async {
      final r = await _montar(tester, fisico);
      final escala = LienzoAdaptable.escalaPara(fisico);

      // Alto: siempre completo, el eje que ajusta no deja franjas.
      expect(r.dibujado.height, closeTo(fisico.height, 0.5));

      // Ancho: todo el disponible salvo cuando pega el tope de ancho, y ahí
      // queda centrado en vez de estirarse.
      expect(r.dibujado.width, closeTo(r.logico.width * escala, 0.5));
      expect(r.dibujado.width, lessThanOrEqualTo(fisico.width + 0.01));
      expect(r.dibujado.center.dx, closeTo(fisico.width / 2, 0.5));
    });
  });

  testWidgets('una pantalla apaisada no estira el diseño a lo ancho',
      (tester) async {
    final r = await _montar(tester, const Size(1280, 800));

    // 1280/800 en el lienzo escalado serían 2048 de ancho: una fila de
    // extremo a extremo ahí se recorre con la vista, no se lee.
    expect(r.logico.width, lessThan(1280));
    expect(r.logico.width, LienzoAdaptable.anchoReferencia * 1.5);
  });

  testWidgets('los recortes del sistema llegan en la escala del lienzo',
      (tester) async {
    const fisico = Size(1200, 1920); // factor 1.5
    final r = await _montar(
      tester,
      fisico,
      recortes: const FakeViewPadding(top: 60, bottom: 30),
    );

    // 60 físicos de notch son 40 dentro de un lienzo dibujado a 1.5x: con el
    // valor sin convertir, el SafeArea de cada pantalla reservaría de más.
    expect(r.padding.top, closeTo(40, 0.01));
    expect(r.padding.bottom, closeTo(20, 0.01));
  });
}
