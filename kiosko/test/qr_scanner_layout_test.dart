// La franja de contenido de la pantalla de escaneo se coloca respecto al
// recuadro que dibuja el painter. Cuando no cabía, el RenderFlex desbordaba en
// cada cuadro y la sonda de diagnóstico convertía ese error en un "Build
// scheduled during frame" que congelaba el kiosko. Esta prueba fija las dos
// invariantes: nada invade el recuadro y nada desborda.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:kigo_kiosco/core/models/kiosko_config.dart';
import 'package:kigo_kiosco/core/notifiers/kiosko_config_notifier.dart';
import 'package:kigo_kiosco/features/registro/services/kiosko_servicio.dart';
import 'package:kigo_kiosco/features/welcome/viewmodels/qr_scanner_viewmodel.dart';
import 'package:kigo_kiosco/features/welcome/views/qr_scanner_view.dart';

const mensajeCorto = 'Bienvenido a Residencial Las Palmas';
const mensajeLargo =
    'Bienvenido a Residencial Las Palmas de la Colina Norte, Etapa 3';

class _NotifierFake extends KioskoConfigNotifier {
  _NotifierFake(super.servicio, this.mensaje);

  final String mensaje;

  @override
  KioskoConfig get config =>
      KioskoConfig.fromJson({'mensaje_bienvenida': mensaje});
}

/// Monta la pantalla con un solo cuadro: el diálogo de consentimiento se pide
/// en un post-frame y su cuenta regresiva dejaría un timer vivo.
Future<void> _montar(WidgetTester tester, Size size, String mensaje) async {
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
    ],
    child: MaterialApp(
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

      final lado = math.min(size.width * 0.66, size.height * 0.45);
      final fondoRecuadro = (size.height - lado) / 2 + lado;

      final marca = tester.getRect(find.text('Kigo'));
      final mensaje = tester.getRect(find.text(mensajeCorto));
      final hint = tester.getRect(find.text('Apunta al código QR'));
      final boton =
          tester.getRect(find.text('No tengo la app Kigo o código QR'));

      // Nada del contenido invade el recuadro.
      expect(mensaje.bottom, lessThanOrEqualTo((size.height - lado) / 2));
      expect(hint.top, greaterThanOrEqualTo(fondoRecuadro));

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
      final lado = math.min(size.width * 0.66, size.height * 0.45);
      expect(
        tester.getRect(find.text(mensajeLargo)).bottom,
        lessThanOrEqualTo((size.height - lado) / 2),
      );
    });
  }
}
