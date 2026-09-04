// Dos arreglos de esta pantalla, fijados aquí:
//
// * La mascota del asistente se montaba sobre "Mira a la cámara para
//   identificarte": con topDelBorde: 48 su bloque (etiqueta + dibujo) bajaba
//   hasta y≈145, más allá del header. Ahora va a la altura del logotipo.
// * La pantalla se podía arrastrar. Es un panel de pared sin nada que leer
//   más abajo, y al deslizar el contenido se descuadraba contra la mascota y
//   los botones flotantes, que viven fuera del scroll.
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:kigo_kiosco/core/models/kiosko_config.dart';
import 'package:kigo_kiosco/core/notifiers/kiosko_config_notifier.dart';
import 'package:kigo_kiosco/core/services/connectivity_service.dart';
import 'package:kigo_kiosco/core/theme/kigo_design.dart';
import 'package:kigo_kiosco/core/widgets/etiqueta_asistente.dart';
import 'package:kigo_kiosco/core/widgets/marca_badge.dart';
import 'package:kigo_kiosco/core/widgets/marco_guia_camara.dart';
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

/// La fuente cuadrada de los tests no mide lo que mide Manrope, y los aires
/// del header son de unos pocos px: con la falsa la instrucción de la cámara
/// se parte en más renglones, sube, y da un solape que en el kiosko real no
/// existe. Las pruebas que miden esos aires cargan la fuente de verdad.
Future<void> _cargarFuenteReal() async {
  final bytes = File('assets/fonts/Manrope-Variable.ttf').readAsBytesSync();
  await (FontLoader('Manrope')
        ..addFont(Future.value(ByteData.view(bytes.buffer))))
      .load();
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

  // El header creció 10px (regresar 44->54, isotipo 48->58, mascota 96->106)
  // y la mascota flota fuera de la fila, pegada al borde derecho: si el
  // lockup vuelve a repartirse la fila con `Spacer` -- que son flex igual que
  // él y le dejaban un tercio del sobrante -- sale encogido, y si pierde su
  // tope de ancho se mete debajo del dibujo.
  for (final lienzo in const [
    Size(800, 1280),
    Size(600, 1024),
    Size(1280, 800),
    Size(411, 891),
    Size(320, 640),
  ]) {
    testWidgets('el header no se encima con la mascota en $lienzo',
        (tester) async {
      await _cargarFuenteReal();
      await _montar(tester, lienzo);

      final dibujo = tester.getRect(find.byType(MascotaAsistente));
      final nombre = tester.getRect(find.text('AUTOnomIA'));
      final logo = tester.getRect(find.byType(MarcaBadge));
      final atras = tester.getRect(find.ancestor(
        of: find.byIcon(Icons.arrow_back_ios_new_rounded),
        matching: find.byType(Container),
      ).first);
      final instruccion =
          tester.getRect(find.text('Mira a la cámara para identificarte'));

      expect(nombre.overlaps(dibujo), isFalse);
      expect(logo.overlaps(dibujo), isFalse);
      expect(logo.overlaps(atras), isFalse);
      // La mascota crece sólo donde cabe: en un teléfono el área facial sube
      // y se quedaría sin ese aire.
      expect(instruccion.overlaps(dibujo), isFalse);

      // El botón de regresar sí mide lo pedido en todos: no depende de nada
      // de alrededor.
      expect(atras.width, moreOrLessEquals(54, epsilon: 0.5));
      expect(atras.height, moreOrLessEquals(54, epsilon: 0.5));
    });
  }

  // El óvalo de la cámara es la pieza elástica de la columna: se lleva el
  // sobrante que quede después de todo lo demás. Lo que esto fija es que
  // siga cabiendo -- que no invada el header de arriba ni el botón de PIN de
  // abajo, ni se salga del lienzo -- y que conserve su proporción 1:1.25, que
  // es lo que lo hace leerse como un encuadre de rostro.
  for (final lienzo in const [
    Size(800, 1280),
    Size(600, 1024),
    Size(1280, 800),
    Size(800, 800),
    Size(411, 891),
    Size(320, 640),
  ]) {
    testWidgets('el óvalo cabe y guarda su proporción en $lienzo',
        (tester) async {
      await _cargarFuenteReal();
      await _montar(tester, lienzo);

      final oval = tester.getRect(find.byType(MarcoGuiaCamara));
      final instruccion =
          tester.getRect(find.text('Mira a la cámara para identificarte'));
      final pin = tester.getRect(find
          .ancestor(
              of: find.text('Acceder por PIN...'),
              matching: find.byType(Container))
          .first);
      final marca = tester.getRect(find.byType(MarcaBadge));
      final mascota = tester.getRect(find.byType(MascotaAsistente));

      expect(oval.height / oval.width, moreOrLessEquals(1.25, epsilon: 0.02),
          reason: 'el óvalo perdió su proporción en $lienzo');

      // Dentro del lienzo y de su padding horizontal.
      expect(oval.left, greaterThanOrEqualTo(34.0 - 0.5));
      expect(oval.right, lessThanOrEqualTo(lienzo.width - 34 + 0.5));
      expect(oval.top, greaterThanOrEqualTo(0.0));
      expect(oval.bottom, lessThanOrEqualTo(lienzo.height));

      // Y sin tocar a sus vecinos, arriba y abajo.
      expect(oval.top, greaterThan(instruccion.bottom));
      expect(oval.bottom, lessThan(pin.top));
      expect(oval.overlaps(marca), isFalse);
      expect(oval.overlaps(mascota), isFalse);
    });
  }

  // La medida en el panel: el óvalo se queda con el sobrante que dejaban los
  // dos `Spacer` de la columna (56px muertos arriba y otros 56 abajo), sin
  // comerse el aire que separa el bloque del header y de la franja de los
  // botones flotantes.
  testWidgets('el óvalo aprovecha el sobrante en el panel', (tester) async {
    await _cargarFuenteReal();
    const panel = Size(800, 1280);
    await _montar(tester, panel);

    final oval = tester.getRect(find.byType(MarcoGuiaCamara));
    expect(oval.height, moreOrLessEquals(704, epsilon: 1));
    expect(oval.width, moreOrLessEquals(704 / 1.25, epsilon: 1));

    // Centrado en horizontal, como estaba.
    expect(oval.center.dx, moreOrLessEquals(panel.width / 2, epsilon: 0.5));

    // Y con aire por los dos lados: contra el header arriba y contra el
    // vigilante abajo (que es lo que el botón de PIN no puede tocar).
    final instruccion =
        tester.getRect(find.text('Mira a la cámara para identificarte'));
    final marca = tester.getRect(find.byType(MarcaBadge));
    final pin = tester.getRect(find
        .ancestor(
            of: find.text('Acceder por PIN...'), matching: find.byType(Container))
        .first);
    final ayuda = tester.getRect(
        find.ancestor(of: find.text('AYUDA'), matching: find.byType(Column)).first);

    expect(instruccion.top - marca.bottom, greaterThan(20));
    expect(ayuda.top - pin.bottom, greaterThan(20));
  });

  // El botón de PIN creció 20px de alto (48 -> 68) con todo su interior a la
  // misma proporción. Lo que esto fija: que siga siendo una pastilla de UN
  // renglón -- a 68 mide 284 de ancho y en un lienzo angosto la etiqueta
  // saltaba de renglón, estirándolo a 98 de alto -- y que no se meta en los
  // botones flotantes de abajo, que es contra lo que está dimensionado el
  // óvalo de la cámara.
  for (final lienzo in const [
    Size(800, 1280),
    Size(800, 1000),
    Size(800, 800),
    Size(411, 891),
    Size(320, 640),
  ]) {
    testWidgets('el botón de PIN no se sobrepone ni se parte en $lienzo',
        (tester) async {
      await _cargarFuenteReal();
      await _montar(tester, lienzo);

      final texto = find.text('Acceder por PIN...');
      final pin = tester.getRect(
          find.ancestor(of: texto, matching: find.byType(Container)).first);
      final parrafo = tester.renderObject<RenderParagraph>(texto);

      // Un renglón: si el botón deja de encoger entero, la etiqueta se parte
      // y la pastilla se estira a lo alto.
      expect(
        parrafo.size.height,
        lessThanOrEqualTo(parrafo.getMaxIntrinsicHeight(double.infinity) + 1),
        reason: 'la etiqueta del PIN se partió en $lienzo',
      );

      final ayuda = tester.getRect(find
          .ancestor(of: find.text('AYUDA'), matching: find.byType(Column))
          .first);
      final microfono = tester.getRect(find
          .ancestor(
            of: find.byWidgetPredicate((w) =>
                w is Icon &&
                (w.icon == Icons.mic_rounded ||
                    w.icon == Icons.mic_none_rounded ||
                    w.icon == Icons.mic_off_rounded)),
            matching: find.byType(Container),
          )
          .first);
      expect(pin.overlaps(ayuda), isFalse,
          reason: 'el PIN se encimó con el vigilante en $lienzo');
      expect(pin.overlaps(microfono), isFalse,
          reason: 'el PIN se encimó con el micrófono en $lienzo');
    });
  }

  // Las medidas pedidas en el panel: 68 de alto, y el icono y la letra al
  // mismo factor. Si alguien sube sólo la caja, el contenido queda nadando
  // dentro y esto lo caza.
  testWidgets('el botón de PIN mide lo pedido en el panel', (tester) async {
    await _cargarFuenteReal();
    await _montar(tester, const Size(800, 1280));

    final texto = find.text('Acceder por PIN...');
    final pin = tester.getRect(
        find.ancestor(of: texto, matching: find.byType(Container)).first);
    final icono = tester.getRect(find.byIcon(Icons.dialpad_rounded));

    expect(pin.height, moreOrLessEquals(68, epsilon: 0.5));
    // 20 y 15 escalados por 68/48.
    expect(icono.width, moreOrLessEquals(20 * 68 / 48, epsilon: 0.5));
    expect(tester.getRect(texto).height,
        moreOrLessEquals(21 * 68 / 48, epsilon: 1.5));
  });

  // Las medidas del header en el panel, sin encoger: el lockup cabe de sobra
  // y no lo toca ningún FittedBox.
  testWidgets('el header mide lo pedido en el panel', (tester) async {
    await _cargarFuenteReal();
    await _montar(tester, const Size(800, 1280));

    expect(tester.getRect(find.byType(MarcaBadge)).width,
        moreOrLessEquals(58, epsilon: 0.5));
    expect(
        tester
            .getRect(find.ancestor(
              of: find.byType(MascotaAsistente),
              matching: find.byType(SizedBox),
            ).first)
            .width,
        moreOrLessEquals(KigoDesign.ladoAsistente + 10, epsilon: 0.5));
  });

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
