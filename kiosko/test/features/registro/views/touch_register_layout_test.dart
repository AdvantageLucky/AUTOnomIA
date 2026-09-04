// La pantalla de captura tenía todo pegado al borde de arriba: header,
// progreso, animación y CTA arrancaban juntos y sobraba medio panel vacío
// abajo. Ahora la animación cae en el centro del panel y el CTA cuelga de
// ella. Encima, el header, el botón de regreso y la mascota crecieron 20px,
// y ahí el riesgo es que se toquen entre sí: por eso esta prueba mide
// separaciones reales contra el árbol, no números sueltos.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:kigo_kiosco/core/models/kiosko_config.dart';
import 'package:kigo_kiosco/core/notifiers/kiosko_config_notifier.dart';
import 'package:kigo_kiosco/core/services/connectivity_service.dart';
import 'package:kigo_kiosco/core/widgets/marca_badge.dart';
import 'package:kigo_kiosco/core/widgets/mascota_asistente.dart';
import 'package:kigo_kiosco/features/registro/services/kiosko_servicio.dart';
import 'package:kigo_kiosco/features/registro/views/touch_register_view.dart';
import 'package:kigo_kiosco/features/registro/views/widgets/face_approach_animation.dart';
import 'package:kigo_kiosco/features/registro/views/widgets/step_indicator.dart';

class _NotifierFake extends KioskoConfigNotifier {
  _NotifierFake(super.servicio);
  @override
  KioskoConfig get config => KioskoConfig.fromJson(const {});
}

/// Caja de la mascota: el dibujo ocupa el 84% de su lado, así que el borde
/// real de lo que flota arriba a la derecha queda un poco más abajo de lo
/// que mide `MascotaAsistente`.
const double _ladoMascota = 116;
const double _sobranteHalo = _ladoMascota * 0.08;

Future<void> _montar(WidgetTester tester, Size pantalla) async {
  tester.view.physicalSize = pantalla;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final servicio = KioskoServicio();
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<KioskoServicio>.value(value: servicio),
        ChangeNotifierProvider<KioskoConfigNotifier>.value(
          value: _NotifierFake(servicio),
        ),
        ChangeNotifierProvider<ConnectivityService>.value(
          value: ConnectivityService(),
        ),
      ],
      child: const MaterialApp(home: TouchRegisterView()),
    ),
  );
}

Rect _cajaAnimacion(WidgetTester tester) => tester.getRect(
  find
      .ancestor(
        of: find.byType(FaceApproachAnimation),
        matching: find.byType(ClipRRect),
      )
      .first,
);

Rect _cta(WidgetTester tester) => tester.getRect(
  find
      .ancestor(
        of: find.text('Reconocimiento Facial'),
        matching: find.byType(Container),
      )
      .first,
);

void main() {
  testWidgets('en el kiosko la animación queda centrada en el panel', (
    tester,
  ) async {
    await _montar(tester, const Size(800, 1280));
    expect(tester.takeException(), isNull);

    final indicador = tester.getRect(find.byType(StepIndicator));
    final caja = _cajaAnimacion(tester);
    final dibujo = tester.getRect(find.byType(FaceApproachAnimation));

    // Centrada de verdad en el panel, no "más abajo que antes": su centro
    // cae en el centro de la pantalla.
    expect(caja.center.dy, moreOrLessEquals(640, epsilon: 1));

    // La caja creció (300 -> 420) y el dibujo creció CON ella: antes se
    // quedaba en sus 280 fijos por más que la caja subiera.
    expect(caja.height, moreOrLessEquals(420, epsilon: 0.5));
    expect(dibujo.height, greaterThan(340));
    expect(
      dibujo.width / dibujo.height,
      moreOrLessEquals(230 / 280, epsilon: 0.02),
    );

    // La separación pedida es un piso; centrar manda cuando sobra panel.
    expect(caja.top - indicador.bottom, greaterThanOrEqualTo(100));

    // El CTA no se despega: conserva los 32 de siempre bajo la animación.
    expect(_cta(tester).top - caja.bottom, moreOrLessEquals(32, epsilon: 0.5));

    // Y el CTA cabe entero en el panel, sin quedar bajo los botones de
    // ayuda/micrófono que el asistente ancla abajo.
    expect(
      _cta(tester).bottom,
      lessThan(tester.getRect(find.text('AYUDA')).top),
    );
  });

  testWidgets('lo de arriba creció 20 sin encimarse entre sí', (tester) async {
    await _montar(tester, const Size(800, 1280));

    final marca = tester.getRect(find.byType(MarcaBadge));
    final titulo = tester.getRect(find.text('AUTOnomIA'));
    final regreso = tester.getRect(
      find.byIcon(Icons.arrow_back_ios_new_rounded),
    );
    final mascota = tester.getRect(find.byType(MascotaAsistente));
    final indicador = tester.getRect(find.byType(StepIndicator));

    // Las tres medidas que se pidieron subir.
    expect(marca.height, moreOrLessEquals(74, epsilon: 0.5)); // 54 + 20
    expect(regreso.height, moreOrLessEquals(64, epsilon: 0.5)); // 44 + 20
    expect(
      mascota.height,
      moreOrLessEquals(_ladoMascota * 0.84, epsilon: 0.5),
    ); // 96 + 20 de caja

    // Nada se encima con nadie: el título no toca ni el botón de regreso ni
    // la mascota, y el indicador arranca por debajo de la mascota completa
    // (su caja, no sólo el dibujo).
    expect(titulo.left, greaterThan(regreso.right));
    expect(titulo.right, lessThan(mascota.left));
    expect(indicador.top, greaterThanOrEqualTo(mascota.bottom + _sobranteHalo));
  });

  testWidgets('en una pantalla corta respeta los 100 y deja hacer scroll', (
    tester,
  ) async {
    await _montar(tester, const Size(600, 1024));
    expect(tester.takeException(), isNull);

    final indicador = tester.getRect(find.byType(StepIndicator));
    final caja = _cajaAnimacion(tester);

    // Sin panel de sobra para centrar, la separación se queda exacta en el
    // piso -- nunca por debajo, que era el riesgo de encimar el progreso.
    expect(caja.top - indicador.bottom, moreOrLessEquals(100, epsilon: 0.5));
    expect(_cta(tester).top - caja.bottom, moreOrLessEquals(32, epsilon: 0.5));
  });
}
