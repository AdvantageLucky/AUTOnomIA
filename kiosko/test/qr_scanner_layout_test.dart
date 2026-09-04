// La franja de contenido de la pantalla de escaneo se coloca respecto al
// recuadro que dibuja el painter. Cuando no cabía, el RenderFlex desbordaba en
// cada cuadro y la sonda de diagnóstico convertía ese error en un "Build
// scheduled during frame" que congelaba el kiosko. Esta prueba fija tres
// invariantes: nada invade el recuadro, nada desborda, y el anillo se dibuja
// justo en el hueco que el layout reservó (no en otro lado).
//
// La geometría se mide sobre la pantalla montada (`claveRecuadroQr` marca el
// hueco del encuadre en el árbol): si la prueba la recalculara por su cuenta
// volvería a validar contra una copia que puede irse quedando atrás. Desde que
// el recuadro cuelga de la pastilla del mensaje ni siquiera se puede -- su
// posición depende de cuántos renglones ocupa el mensaje con la fuente que
// esté cargada.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:kigo_kiosco/core/models/kiosko_config.dart';
import 'package:kigo_kiosco/core/theme/kigo_design.dart';
import 'package:kigo_kiosco/core/widgets/boton_asistente_flotante.dart';
import 'package:kigo_kiosco/core/widgets/mascota_asistente.dart';
import 'package:kigo_kiosco/features/welcome/views/widgets/comunidad_badge.dart';
import 'package:kigo_kiosco/core/notifiers/kiosko_config_notifier.dart';
import 'package:kigo_kiosco/core/services/connectivity_service.dart';
import 'package:kigo_kiosco/features/registro/services/kiosko_servicio.dart';
import 'package:kigo_kiosco/features/welcome/viewmodels/qr_scanner_viewmodel.dart';
import 'package:kigo_kiosco/features/welcome/views/qr_scanner_view.dart';

/// El hueco del encuadre tal como quedó en la pantalla montada.
Rect recuadroDe(WidgetTester tester) =>
    tester.getRect(find.byKey(claveRecuadroQr));

const mensajeCorto = 'Bienvenido a Residencial Las Palmas';
/// Un nombre corto: con el largo, la fuente cuadrada de los tests llena el
/// ancho sola y taparía que la pastilla se esté encogiendo hasta su texto.
const mensajeMinimo = 'FEPRO';

/// Del largo del que se usa en el panel de verdad. `mensajeCorto` es bastante
/// más largo y con la fuente cuadrada de los tests se va a cuatro renglones,
/// donde el FittedBox ya tiene que encoger la pastilla.
const mensajePanel = 'BIENVENIDO A FEPRO 2026';
const mensajeLargo =
    'Bienvenido a Residencial Las Palmas de la Colina Norte, Etapa 3';

class _NotifierFake extends KioskoConfigNotifier {
  _NotifierFake(super.servicio, this.mensaje);

  final String mensaje;

  @override
  KioskoConfig get config =>
      KioskoConfig.fromJson({'mensaje_bienvenida': mensaje});
}

/// La fuente cuadrada de los tests no mide lo mismo que la real, y las
/// separaciones de 10px del panel están calculadas contra Manrope: con la
/// falsa el bloque de abajo sale 23px más corto y los huecos no dan.
Future<void> _cargarFuenteReal() async {
  final bytes = File('assets/fonts/Manrope-Variable.ttf').readAsBytesSync();
  await (FontLoader('Manrope')
        ..addFont(Future.value(ByteData.view(bytes.buffer))))
      .load();
}

/// Monta la pantalla con un solo cuadro: el diálogo de consentimiento se pide
/// en un post-frame y su cuenta regresiva dejaría un timer vivo.
Future<void> _montar(
  WidgetTester tester,
  Size size,
  String mensaje, {
  ThemeData? tema,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final servicio = KioskoServicio();

  await tester.pumpWidget(MultiProvider(
    providers: [
      Provider<KioskoServicio>.value(value: servicio),
      ChangeNotifierProvider<KioskoConfigNotifier>.value(
        value: _NotifierFake(servicio, mensaje),
      ),
      // BotonAsistente (dentro de BotonAsistenteFlotante, agregado a
      // QrScannerView) lo lee vía context.watch -- no se llama iniciar(),
      // así que se queda en su default (isOffline: false) sin timers vivos.
      ChangeNotifierProvider<ConnectivityService>.value(
        value: ConnectivityService(),
      ),
    ],
    child: MaterialApp(
      theme: tema,
      home: QrScannerView(
        viewModel: QrScannerViewModel(),
        onSinCodigo: () {},
      ),
    ),
  ));
}

void main() {
  for (final size in const [
    Size(800, 1280), // panel del kiosko
    Size(361, 784), // telefono en portrait
    Size(411, 891),
    Size(320, 640), // pantalla chica
    Size(784, 361), // apaisado: el caso que dejaba huecos negativos
  ]) {
    testWidgets('sin desbordes ni invasiones en $size', (tester) async {
      await _montar(tester, size, mensajeCorto);

      expect(tester.takeException(), isNull);

      final recuadro = recuadroDe(tester);

      final marca = tester.getRect(find.text('AUTOnomIA'));
      final mensaje = tester.getRect(find.text(mensajeCorto));
      final hint = tester.getRect(find.text('Apunta al código QR'));
      final boton =
          tester.getRect(find.text('No tengo la app AUTOnomIA o código QR'));

      // Nada del contenido invade el recuadro.
      expect(mensaje.bottom, lessThanOrEqualTo(recuadro.top));
      expect(hint.top, greaterThanOrEqualTo(recuadro.bottom));

      // Y el orden vertical es el esperado.
      expect(marca.bottom, lessThan(mensaje.top));
      expect(hint.bottom, lessThan(boton.top));
      expect(boton.bottom, lessThanOrEqualTo(size.height));
    });

    testWidgets('el nombre largo salta de renglón, no se recorta en $size',
        (tester) async {
      await _montar(tester, size, mensajeLargo);

      expect(tester.takeException(), isNull);

      final parrafo =
          tester.renderObject<RenderParagraph>(find.text(mensajeLargo));

      // Nada de puntos suspensivos: se ve el nombre completo.
      expect(parrafo.didExceedMaxLines, isFalse);

      // Y para lograrlo usó más de un renglón.
      final unRenglon = parrafo.getMaxIntrinsicHeight(double.infinity);
      expect(parrafo.size.height, greaterThan(unRenglon));

      // Sigue sin invadir el recuadro.
      expect(
        tester.getRect(find.text(mensajeLargo)).bottom,
        lessThanOrEqualTo(recuadroDe(tester).top),
      );
    });

    // El bug que esto congela: el painter centraba el recuadro en vertical
    // mientras el layout lo subía al 32% del sobrante, así que en el panel de
    // 800x1280 el anillo se dibujaba 158px más abajo del hueco y quedaba
    // encima del "Apunta al código QR". Las otras pruebas no lo veían porque
    // solo miran dónde cae el texto, nunca dónde pinta el painter.
    testWidgets('el anillo se dibuja en el hueco reservado en $size',
        (tester) async {
      await _montar(tester, size, mensajeCorto);

      final recuadro = recuadroDe(tester);
      final overlay = tester
          .renderObjectList<RenderCustomPaint>(find.byType(CustomPaint))
          .firstWhere(
            (r) => r.painter.runtimeType.toString() == '_QrOverlayPainter',
          );

      // Tolerante con la respiración del anillo (late entre 0.97 y 1.0 de su
      // lado alrededor de su propio centro), estricta con dónde está.
      expect(
        overlay,
        paints
          ..something((Symbol metodo, List<dynamic> argumentos) {
            if (metodo != #drawRRect) return false;
            final rrect = argumentos.first as RRect;
            final centro = rrect.outerRect.center;
            return (centro - recuadro.center).distance < 0.5 &&
                rrect.width <= recuadro.width + 0.5 &&
                rrect.width >= recuadro.width * 0.96;
          }),
      );
    });
  }

  // El CTA en el panel real: ancho completo de la franja y bajo. Venía de
  // 236px de alto con el texto partido en tres renglones, y el bloque no
  // cabía -- el FittedBox lo encogía al 93%, así que ni siquiera llegaba a
  // ocupar el ancho disponible.
  //
  // Con la fuente real: la fuente cuadrada de los tests parte el subtítulo en
  // dos renglones y estira el bloque, y con eso entraría el FittedBox y el
  // CTA saldría encogido. Con Manrope el bloque mide los 215 que caben en su
  // franja.
  testWidgets('el CTA mide 750x110 en el panel', (tester) async {
    await _cargarFuenteReal();

    const panel = Size(800, 1280);
    await _montar(tester, panel, mensajeCorto, tema: KigoDesign.darkTheme);

    final texto = find.text('No tengo la app AUTOnomIA o código QR');
    final boton = tester.getRect(
      find.ancestor(of: texto, matching: find.byType(AnimatedContainer)).first,
    );

    // Las medidas pedidas para el panel: 750 x 110 clavados. Que el ancho dé
    // exacto es además lo que prueba que el FittedBox de la franja no está
    // encogiendo el bloque.
    expect(boton.width, moreOrLessEquals(750, epsilon: 0.5));
    expect(boton.height, moreOrLessEquals(110, epsilon: 0.5));

    // Y el texto entra dentro de esos 110 sin que la red del FittedBox
    // interior tenga que achicarlo: como mucho dos renglones.
    final parrafo = tester.renderObject<RenderParagraph>(texto);
    final unRenglon = parrafo.getMaxIntrinsicHeight(double.infinity);
    expect(parrafo.size.height, lessThanOrEqualTo(unRenglon * 2 + 1));
    expect(parrafo.size.height, lessThanOrEqualTo(boton.height));

    // Sin encimarse con nada: ni con el subtítulo de arriba ni con la reserva
    // de abajo que deja libre el micrófono/vigilante flotante.
    final sub = tester.getRect(
      find.text('Tu código personal o el de tu invitación'),
    );
    expect(sub.bottom, lessThan(boton.top));
    // El aire de abajo ya no es el bloque de 110 reservado a ojo, sino el
    // borde real de los botones flotantes -- se comprueba en su propia
    // prueba, aquí basta con que no los toque. Contra la huella completa del
    // botón (círculo + etiqueta "AYUDA"), que es lo que el CTA se estaba
    // comiendo.
    expect(
      boton.bottom,
      lessThan(panel.height -
          KigoDesign.offsetBotonesFlotantes -
          KigoDesign.altoBotonAccionConEtiqueta),
    );
  });

  // La cadena de arriba a abajo, con las separaciones exactas: 20 de la
  // pastilla al recuadro, 10 del recuadro al bloque de textos + CTA. Antes el
  // bloque colgaba del piso y
  // dejaba 143px muertos bajo el recuadro; y del otro lado, con el recuadro
  // clavado a una fracción fija, quedaban otros 145 muertos entre la pastilla
  // y el encuadre -- el mensaje del panel entra en un renglón y la franja de
  // arriba estaba dimensionada para tres.
  //
  // Con la fuente real: la cuadrada de los tests deja el bloque 23px más
  // corto y los huecos no serían los del panel.
  testWidgets('pastilla a 20 del recuadro, y el recuadro a 10 de los textos',
      (tester) async {
    await _cargarFuenteReal();

    const panel = Size(800, 1280);
    await _montar(tester, panel, mensajePanel, tema: KigoDesign.darkTheme);

    final recuadro = recuadroDe(tester);
    final badge = tester.getRect(find.byType(ComunidadBadge));
    final hint = tester.getRect(find.text('Apunta al código QR'));
    final boton = tester.getRect(find.ancestor(
      of: find.text('No tengo la app AUTOnomIA o código QR'),
      matching: find.byType(AnimatedContainer),
    ).first);

    // El recuadro cuelga de la pastilla, con el doble de aire que abajo: la
    // pastilla tiene borde y relleno propios y a 10 se le pegaba encima.
    expect(recuadro.top - badge.bottom, moreOrLessEquals(20, epsilon: 0.5));

    // Y el bloque cuelga del recuadro, igual de pegado.
    expect(hint.top - recuadro.bottom, moreOrLessEquals(10, epsilon: 0.5));

    // Lo que sobra queda abajo: el CTA ya no se apoya en los botones
    // flotantes, pero tampoco los toca. La huella se mide sobre el widget, no
    // sobre la constante -- el círculo del vigilante lleva la etiqueta
    // "AYUDA" debajo y contar sólo el círculo es lo que una vez los encimó.
    final flotante = tester.getRect(
      find.ancestor(of: find.text('AYUDA'), matching: find.byType(Column)).first,
    );
    expect(flotante.height,
        moreOrLessEquals(KigoDesign.altoBotonAccionConEtiqueta, epsilon: 0.5));
    expect(flotante.top - boton.bottom, greaterThanOrEqualTo(10));
  });

  // El bloque de abajo sube lo mismo que el recuadro: es lo que se pidió --
  // subir el encuadre, sus textos y el CTA, no sólo el encuadre. Si alguien
  // vuelve a colgar el bloque del piso, esto lo caza.
  testWidgets('el bloque de abajo sube con el recuadro', (tester) async {
    await _cargarFuenteReal();

    const panel = Size(800, 1280);
    await _montar(tester, panel, mensajePanel, tema: KigoDesign.darkTheme);

    final recuadro = recuadroDe(tester);
    final boton = tester.getRect(find.ancestor(
      of: find.text('No tengo la app AUTOnomIA o código QR'),
      matching: find.byType(AnimatedContainer),
    ).first);

    // Con el mensaje del panel en un renglón el recuadro sube bien por encima
    // del tope viejo (428) -- la pastilla mide 127 y no 264.
    expect(recuadro.top, lessThan(320));

    // Y el CTA termina antes de la mitad de abajo del panel: el aire que
    // liberó la franja de arriba se lo quedó el piso, no un hueco entre el
    // encuadre y su texto.
    expect(boton.bottom, lessThan(panel.height - 130));
  });

  // La pastilla va a x3 y de ancho completo. Con la fuente cuadrada de los
  // tests el mensaje del panel se parte en varios renglones y pasa de 180 de
  // alto: la franja se estira para dárselos en vez de que el FittedBox la
  // encoja.
  testWidgets('la pastilla aprovecha la franja de arriba', (tester) async {
    const panel = Size(800, 1280);
    await _montar(tester, panel, mensajePanel);

    final badge = tester.getRect(find.byType(ComunidadBadge));
    final recuadro = recuadroDe(tester);

    expect(badge.height, greaterThan(180));

    // Sin invadir el recuadro ni desbordar su franja: si crece de más, el
    // FittedBox la encogería y esto dejaría de cumplirse.
    expect(badge.bottom, lessThan(recuadro.top));
    expect(badge.width, moreOrLessEquals(panel.width - 16, epsilon: 0.5));
  });

  // No como fracción del ancho: en un lienzo mayor sigue midiendo lo pedido.
  testWidgets('el CTA mide 750x110 también en un lienzo mayor',
      (tester) async {
    await _montar(tester, const Size(1080, 1920), mensajeCorto);

    final boton = tester.getRect(find.ancestor(
      of: find.text('No tengo la app AUTOnomIA o código QR'),
      matching: find.byType(AnimatedContainer),
    ).first);

    expect(boton.width, moreOrLessEquals(750, epsilon: 0.5));
    expect(boton.height, moreOrLessEquals(110, epsilon: 0.5));
  });

  // Las dos medidas pedidas son absolutas, no fracciones del lienzo: salían
  // bien sólo si el panel medía exactamente 800 de ancho, y en cualquier otro
  // parecía que el cambio no se había aplicado.
  testWidgets('el recuadro mide 503x503 aunque el lienzo sea mayor',
      (tester) async {
    for (final lienzo in const [Size(800, 1280), Size(1080, 1920)]) {
      final r = rectRecuadroQr(lienzo);
      expect(r.width, moreOrLessEquals(503, epsilon: 0.01), reason: '$lienzo');
      expect(r.height, moreOrLessEquals(503, epsilon: 0.01), reason: '$lienzo');
    }

    // Y en un lienzo donde no quepan, sigue mandando la fracción.
    expect(rectRecuadroQr(const Size(600, 960)).width, lessThan(503));
  });

  // La pastilla llevaba un Center que la encogía hasta abrazar su texto: su
  // ancho lo decidía el mensaje del dashboard, no el hueco reservado, así que
  // agrandarla no se notaba. Con un mensaje corto se ve; con uno largo la
  // fuente cuadrada de los tests llena el ancho sola y lo tapa.
  testWidgets('la pastilla llena la franja aunque el mensaje sea corto',
      (tester) async {
    const panel = Size(800, 1280);
    await _montar(tester, panel, mensajeMinimo);

    expect(
      tester.getRect(find.byType(ComunidadBadge)).width,
      moreOrLessEquals(panel.width - 16, epsilon: 0.5),
    );
  });

  // La mascota del asistente vive pegada al techo a la derecha y el badge de
  // comunidad es de ancho completo: el badge se estaba metiendo por debajo de
  // ella (su borde de arriba caía 10px adentro), que es como se veía en el
  // panel real.
  testWidgets('el badge de comunidad no se mete bajo el asistente',
      (tester) async {
    const panel = Size(800, 1280);
    await _montar(tester, panel, mensajeCorto);

    final badge = tester.getRect(find.byType(ComunidadBadge));
    final mascota = tester.getRect(find.descendant(
      of: find.byType(BotonAsistenteFlotante),
      matching: find.byType(MascotaAsistente),
    ));
    final etiqueta = tester.getRect(find.text('Asistente IA'));

    expect(badge.overlaps(mascota), isFalse);
    expect(badge.overlaps(etiqueta), isFalse);

    // Arranca debajo de la huella completa que el diseño reserva arriba, no
    // apenas rozando el borde de la mascota.
    expect(
      badge.top,
      greaterThanOrEqualTo(KigoDesign.clearanceAsistenteArriba),
    );

    // Con aire de por medio, no rozandola: a 8px el borde de la pastilla
    // parecia parte del bloque del asistente cuando se mira el kiosko de
    // lejos, que es la unica distancia a la que se mira un kiosko.
    expect(badge.top - mascota.bottom, greaterThan(16));

    // Pero pegada, no flotando: la pastilla se cuelga del asistente. Si
    // alguien la vuelve a centrar en la franja, esto lo caza.
    expect(badge.top - mascota.bottom, lessThan(32));
  });

  // La fuente cuadrada del resto de las pruebas no dice nada de cuantos
  // renglones ocupa el mensaje de verdad, y ese es justo el punto: con el
  // cromo lateral creciendo a x3 el mensaje del panel se partia en dos
  // renglones, la pastilla salia corta y alta, y ese alto de mas era el que
  // la subia contra la mascota. Esta monta la pantalla con Manrope -- la
  // fuente real -- para fijar que entra de largo, en un solo renglon.
  testWidgets('el mensaje del panel entra en un renglon con la fuente real',
      (tester) async {
    await _cargarFuenteReal();

    const panel = Size(800, 1280);
    await _montar(tester, panel, mensajePanel, tema: KigoDesign.darkTheme);

    final parrafo = tester.renderObject<RenderParagraph>(find.descendant(
      of: find.byType(ComunidadBadge),
      matching: find.byType(RichText),
    ));
    final badge = tester.getRect(find.byType(ComunidadBadge));

    // Un renglon: el alto del parrafo es fontSize (16*3) por el height 1.25.
    expect(parrafo.size.height, moreOrLessEquals(48 * 1.25, epsilon: 1));

    // Y ocupando el largo de la pastilla, no una franja estrecha en medio.
    expect(parrafo.size.width, greaterThan(badge.width * 0.75));
    expect(badge.width, moreOrLessEquals(panel.width - 16, epsilon: 0.5));
  });
}
