// El CTA de abajo pasó de 76 a 150 de alto por pedido de diseño. La letra
// tenía que crecer con él: con los tamaños viejos quedaba flotando chiquita
// en una caja del doble de grande. Esta prueba fija las dos mitades -- que la
// caja mida lo pedido y que su contenido siga siendo proporcional a ella.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:kigo_kiosco/core/models/kiosko_config.dart';
import 'package:kigo_kiosco/core/notifiers/kiosko_config_notifier.dart';
import 'package:kigo_kiosco/core/services/connectivity_service.dart';
import 'package:kigo_kiosco/features/registro/services/kiosko_servicio.dart';
import 'package:kigo_kiosco/features/registro/views/touch_register_view.dart';

class _NotifierFake extends KioskoConfigNotifier {
  _NotifierFake(super.servicio);
  @override
  KioskoConfig get config => KioskoConfig.fromJson(const {});
}

void main() {
  testWidgets('el CTA mide 150 de alto y su letra va a esa escala',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1280);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

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
      child: const MaterialApp(home: TouchRegisterView()),
    ));

    expect(tester.takeException(), isNull);

    final titulo = find.text('Reconocimiento Facial');
    final boton = tester.getRect(
      find.ancestor(of: titulo, matching: find.byType(Container)).first,
    );
    expect(boton.height, moreOrLessEquals(150, epsilon: 0.5));

    // Proporcional, no un número congelado: el título ocupa ~27% del alto del
    // botón (40 sobre 150). Con los 20 de antes caía al 13%.
    final estilo = tester.renderObject<RenderParagraph>(titulo).text.style;
    expect(estilo?.fontSize, greaterThan(boton.height * 0.22));

    // Y el subtítulo acompaña, sin volverse un renglón perdido.
    final sub = tester.renderObject<RenderParagraph>(
      find.text('Presionar para continuar'),
    );
    expect(sub.text.style?.fontSize, greaterThan(boton.height * 0.14));

    // Nada se sale de la caja fija -- el FittedBox la protege aunque un
    // idioma traiga un texto más largo.
    final alto = tester.renderObject<RenderParagraph>(titulo).size.height +
        tester.getRect(find.text('Presionar para continuar')).height;
    expect(alto, lessThan(boton.height));
  });
}
