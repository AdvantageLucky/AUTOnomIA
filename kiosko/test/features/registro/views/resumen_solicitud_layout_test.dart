// La pantalla de "Esperando aprobación" se podía arrastrar: al deslizar, el
// StepIndicator se metía debajo de la mascota (que va en el Stack, fuera del
// scroll) y la tarjeta con la foto se iba de la vista. Aquí se fija que la
// pantalla NO scrollea, que la mascota queda por encima del indicador de
// pasos -- como en el resto del registro -- y que todo entra sin arrastrar.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:kigo_kiosco/core/models/kiosko_config.dart';
import 'package:kigo_kiosco/core/notifiers/kiosko_config_notifier.dart';
import 'package:kigo_kiosco/core/services/connectivity_service.dart';
import 'package:kigo_kiosco/core/theme/kigo_design.dart';
import 'package:kigo_kiosco/core/widgets/etiqueta_asistente.dart';
import 'package:kigo_kiosco/core/widgets/mascota_asistente.dart';
import 'package:kigo_kiosco/features/registro/models/user_registration_model.dart';
import 'package:kigo_kiosco/features/registro/services/kiosko_servicio.dart';
import 'package:kigo_kiosco/features/registro/views/resumen_solicitud_view.dart';
import 'package:kigo_kiosco/features/registro/views/widgets/step_indicator.dart';

class _NotifierFake extends KioskoConfigNotifier {
  _NotifierFake(super.servicio);
  @override
  KioskoConfig get config => KioskoConfig.fromJson(const {});
}

/// El caso más alto que puede mostrar la pantalla: placa y motivo suman dos
/// renglones extra a la tarjeta.
UserRegistrationModel _datosLargos() => UserRegistrationModel(
      nombreCompleto: 'Visitante',
      casaDestino: 'PRINCIPAL · Casa 101',
      placa: 'ABC-1234',
    )..motivo = 'Entrega de paquetería';

Future<void> _montar(WidgetTester tester, Size lienzo) async {
  tester.view.physicalSize = lienzo;
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
    child: MaterialApp(
      home: ResumenSolicitudView(registrationData: _datosLargos()),
    ),
  ));
}

void main() {
  testWidgets('no scrollea: arrastrar no mueve el indicador ni la tarjeta',
      (tester) async {
    await _montar(tester, const Size(800, 1280));

    expect(
      find.byType(Scrollable),
      findsNothing,
      reason: 'la pantalla debe ser fija, sin SingleChildScrollView',
    );

    final indicadorAntes = tester.getRect(find.byType(StepIndicator));
    final tarjetaAntes = tester.getRect(find.text('Visitante'));

    // Un arrastre de arriba hacia abajo y otro al revés: ninguno debe correr
    // nada de sitio.
    await tester.drag(find.text('Visitante'), const Offset(0, 300));
    await tester.pump();
    await tester.drag(find.text('Visitante'), const Offset(0, -300));
    await tester.pump();

    expect(tester.getRect(find.byType(StepIndicator)), indicadorAntes);
    expect(tester.getRect(find.text('Visitante')), tarjetaAntes);
  });

  testWidgets('la mascota queda ARRIBA de la barra de progreso, sin solapar',
      (tester) async {
    await _montar(tester, const Size(800, 1280));

    final etiqueta = tester.getRect(find.byType(EtiquetaAsistente));
    final dibujo = tester.getRect(find.byType(MascotaAsistente));
    final indicador = tester.getRect(find.byType(StepIndicator));

    // La etiqueta "Asistente IA" va ARRIBA del dibujo y el dibujo arriba del
    // indicador: el bloque completo queda por encima, sin solape.
    expect(etiqueta.bottom, lessThanOrEqualTo(dibujo.top));
    expect(dibujo.bottom, lessThanOrEqualTo(indicador.top));

    // Y no por milagro: el bloque cabe porque el contenido arranca en
    // KigoDesign.clearanceAsistenteArriba, que es justo lo que mide.
    expect(indicador.top,
        moreOrLessEquals(KigoDesign.clearanceAsistenteArriba, epsilon: 0.5));
  });

  testWidgets('todo entra en el panel del kiosko sin encoger ni recortar',
      (tester) async {
    await _montar(tester, const Size(800, 1280));
    expect(tester.takeException(), isNull);

    // Sin escala: el indicador ocupa el ancho completo del contenido
    // (800 - 42 de padding a cada lado). Si el FittedBox hubiera tenido que
    // achicar, sería menor.
    expect(tester.getRect(find.byType(StepIndicator)).width,
        moreOrLessEquals(716, epsilon: 0.5));

    // Y el último dato de la tarjeta se ve entero, sin quedar debajo de los
    // botones flotantes de abajo.
    final ultimoDato = tester.getRect(find.text('Entrega de paquetería'));
    expect(ultimoDato.bottom, lessThan(1280 - 110));
  });

  testWidgets('en una pantalla corta encoge en bloque en vez de recortar',
      (tester) async {
    await _montar(tester, const Size(800, 820));
    expect(tester.takeException(), isNull);

    final indicador = tester.getRect(find.byType(StepIndicator));
    expect(indicador.width, lessThan(716),
        reason: 'aquí sí tiene que entrar el scaleDown');

    final ultimoDato = tester.getRect(find.text('Entrega de paquetería'));
    expect(ultimoDato.bottom, lessThan(820));
  });
}
