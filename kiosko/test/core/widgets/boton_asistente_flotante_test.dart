// El asistente se cuelga como HERMANO del Scaffold dentro de un Stack en
// varias pantallas (registro, residentes), no como hijo suyo. Ahí su texto se
// quedaba sin ancestro Material y Flutter le pintaba el subrayado amarillo
// doble de "texto sin estilo" -- visible en el equipo bajo "Asistente IA".
// Esta prueba lo monta justo así, sin Material arriba, que es el caso que la
// rompía.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:kigo_kiosco/core/models/kiosko_config.dart';
import 'package:kigo_kiosco/core/notifiers/kiosko_config_notifier.dart';
import 'package:kigo_kiosco/core/services/connectivity_service.dart';
import 'package:kigo_kiosco/core/widgets/boton_asistente_flotante.dart';
import 'package:kigo_kiosco/features/registro/services/kiosko_servicio.dart';

class _NotifierFake extends KioskoConfigNotifier {
  _NotifierFake(super.servicio);
  @override
  KioskoConfig get config => KioskoConfig.fromJson(const {});
}

void main() {
  testWidgets('la etiqueta no sale subrayada sin un Material arriba',
      (tester) async {
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
      // MaterialApp (sus tooltips necesitan un Overlay) pero SIN Scaffold ni
      // Material envolviendo al asistente: exactamente como lo montan
      // registro y residentes, colgado del Stack junto al Scaffold.
      child: MaterialApp(
        home: Stack(
          children: [
            BotonAsistenteFlotante(
              topDelBorde: 24,
              mostrarEtiqueta: true,
              onRespuestaLibre: (_) {},
              onCampoExtraido: (_) {},
            ),
          ],
        ),
      ),
    ));

    final estilo = tester
        .renderObject<RenderParagraph>(find.text('Asistente IA'))
        .text
        .style;

    // `TextDecoration.none` o sin decoración: lo que no puede es venir
    // subrayado (el fallback sin Material trae underline amarillo doble).
    expect(
      estilo?.decoration ?? TextDecoration.none,
      TextDecoration.none,
      reason: 'la etiqueta quedó con ${estilo?.decoration} '
          '(${estilo?.decorationColor})',
    );
  });
}
