// Dos arreglos de esta pantalla, fijados aquí:
//
// * La mascota del asistente se montaba sobre "Mira a la cámara para
//   identificarte": con topDelBorde: 48 su bloque (etiqueta + dibujo) bajaba
//   hasta y≈145, más allá del header. Ahora va a la altura del logotipo.
// * La pantalla se podía arrastrar. Es un panel de pared sin nada que leer
//   más abajo, y al deslizar el contenido se descuadraba contra la mascota y
//   los botones flotantes, que viven fuera del scroll.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:kigo_kiosco/core/models/kiosko_config.dart';
import 'package:kigo_kiosco/core/notifiers/kiosko_config_notifier.dart';
import 'package:kigo_kiosco/core/services/connectivity_service.dart';
import 'package:kigo_kiosco/core/theme/kigo_design.dart';
import 'package:kigo_kiosco/core/widgets/etiqueta_asistente.dart';
import 'package:kigo_kiosco/core/widgets/mascota_asistente.dart';
import 'package:kigo_kiosco/features/registro/services/kiosko_servicio.dart';
import 'package:kigo_kiosco/features/residente/views/residente_acceso_view.dart';

class _NotifierFake extends KioskoConfigNotifier {
  _NotifierFake(super.servicio);
  @override
  KioskoConfig get config => KioskoConfig.fromJson(const {});
}

/// El consentimiento facial ya dado: sin esto la vista abre el diálogo de
/// consentimiento en vez de la pantalla que queremos medir. La cámara sí se
/// deja fallar -- la vista lo resuelve con su propio placeholder y el resto
/// del layout es idéntico.
void _consentimientoYaDado() {
  const canal = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(canal, (llamada) async {
    if (llamada.method == 'read') return '2026-01-01T00:00:00.000';
    return null;
  });
  addTearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(canal, null);
  });
}

Future<void> _montar(WidgetTester tester, Size lienzo) async {
  tester.view.physicalSize = lienzo;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  _consentimientoYaDado();

  final servicio = KioskoServicio();
  await tester.pumpWidget(MultiProvider(
    providers: [
      Provider<KioskoServicio>.value(value: servicio),
      ChangeNotifierProvider<KioskoConfigNotifier>.value(
        value: _NotifierFake(servicio),
      ),
      ChangeNotifierProvider<ConnectivityService>.value(
        value: ConnectivityService(),
      ),
    ],
    child: MaterialApp(
      theme: KigoDesign.darkTheme,
      home: const ResidenteAccesoView(),
    ),
  ));
  await tester.pump();
}

void main() {
  // El panel del kiosko y una pantalla más corta: ahí el Spacer de arriba se
  // achica y el texto de la cámara sube, que es donde se vio el solape.
  for (final lienzo in const [Size(800, 1280), Size(800, 1000)]) {
    testWidgets('el asistente va a la altura del logotipo, no sobre el texto '
        'en $lienzo', (tester) async {
      await _montar(tester, lienzo);

      final dibujo = tester.getRect(find.byType(MascotaAsistente));
      final etiqueta = tester.getRect(find.byType(EtiquetaAsistente));
      final logo = tester.getRect(find.text('AUTOnomIA'));
      final instruccion =
          tester.getRect(find.text('Mira a la cámara para identificarte'));

      // Lo que se reportó: la mascota encima del texto de la cámara.
      expect(dibujo.bottom, lessThan(instruccion.top),
          reason: 'la mascota no puede solaparse con la instrucción');
      expect(etiqueta.top, greaterThanOrEqualTo(0.0),
          reason: 'subirla no puede sacarla de la pantalla');

      // Y dónde debe quedar: centrada en el logotipo, no debajo.
      expect(dibujo.center.dy, moreOrLessEquals(logo.center.dy, epsilon: 12));
    });
  }

  // Lienzo a propósito más corto que cualquier panel real: es la única forma
  // de que sobre contenido y el scroll tenga a dónde ir. Cuando todo cabe,
  // Flutter ni siquiera acepta el arrastre (shouldAcceptUserOffset), así que
  // probarlo en 800x1280 no demostraría nada.
  testWidgets('no se puede deslizar: arrastrar no mueve nada', (tester) async {
    await _montar(tester, const Size(800, 600));

    final logoAntes = tester.getRect(find.text('AUTOnomIA'));
    final ovaloAntes = tester.getRect(find.byType(ClipOval).first);

    // Se mide CON el dedo abajo: con BouncingScrollPhysics el contenido se
    // arrastra aunque no haya nada que scrollear (el rebote) y vuelve solo al
    // soltar, así que soltar antes de medir no probaría nada.
    for (final desplazamiento in const [320.0, -320.0]) {
      final dedo = await tester.startGesture(const Offset(400, 300));
      await dedo.moveBy(Offset(0, desplazamiento));
      await tester.pump();

      expect(tester.getRect(find.text('AUTOnomIA')), logoAntes);
      expect(tester.getRect(find.byType(ClipOval).first), ovaloAntes);

      await dedo.up();
      // pumpAndSettle no sirve aquí: la mascota anima en bucle y nunca
      // "asienta". Un segundo alcanza de sobra para el rebote.
      await tester.pump(const Duration(seconds: 1));
    }
  });

  // Sin scroll, lo que no cabe ya no se puede ir a buscar arrastrando: el
  // óvalo tiene que encogerse solo para que el botón de PIN no termine
  // debajo del micrófono/vigilante.
  for (final alto in const [1280.0, 1066.0, 1000.0, 900.0, 800.0]) {
    testWidgets('el botón de PIN queda sobre los botones flotantes con '
        'alto $alto', (tester) async {
      await _montar(tester, Size(800, alto));
      expect(tester.takeException(), isNull);

      final pin = tester.getRect(find.text('Acceder por PIN...'));
      final techoBotonesFlotantes = alto -
          KigoDesign.offsetBotonesFlotantes -
          KigoDesign.ladoBotonAccion;
      expect(pin.bottom, lessThan(techoBotonesFlotantes));
    });
  }
}
