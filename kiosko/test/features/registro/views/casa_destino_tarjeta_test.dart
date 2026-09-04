// Las tarjetas de calle/tipo/número crecieron 30 de alto por pedido de
// diseño, y el chip del ícono subió con ellas para no quedar chico dentro de
// una tarjeta más alta. Esta prueba fija las dos mitades -- el alto pedido y
// la proporción del ícono -- y de paso que NO cambió nada más: el ancho, el
// texto y el margen entre tarjetas siguen donde estaban.
//
// La pantalla se alimenta del caché local: con el kiosko "sin red" el
// servicio devuelve los destinos guardados y no toca la API, que es la única
// forma de renderizar las tarjetas reales en una prueba.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:kigo_kiosco/core/models/kiosko_config.dart';
import 'package:kigo_kiosco/core/notifiers/kiosko_config_notifier.dart';
import 'package:kigo_kiosco/core/services/connectivity_service.dart';
import 'package:kigo_kiosco/core/services/local_cache_db.dart';
import 'package:kigo_kiosco/core/widgets/presionable.dart';
import 'package:kigo_kiosco/features/registro/services/kiosko_servicio.dart';
import 'package:kigo_kiosco/features/registro/views/casa_destino_view.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _NotifierFake extends KioskoConfigNotifier {
  _NotifierFake(super.servicio);
  @override
  KioskoConfig get config => KioskoConfig.fromJson(const {});
}

class _SinRed extends ConnectivityService {
  @override
  bool get isOffline => true;
}

/// Alto de la tarjeta tal como se mide con el margen entre tarjetas incluido
/// (16): la caja visible mide 132.4, que son los 102.4 de antes + 30.
const double _altoTarjetaConMargen = 148.4;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  testWidgets('las tarjetas de destino miden 30 más y su ícono acompaña', (
    tester,
  ) async {
    // Sin estos mocks la pantalla revienta por los canales nativos (que no
    // existen en pruebas), no por el layout, que es lo que se mide.
    const secure = MethodChannel(
      'plugins.it_nomads.com/flutter_secure_storage',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secure, (_) async => null);
    const tts = MethodChannel('flutter_tts');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(tts, (_) async => 1);

    tester.view.physicalSize = const Size(800, 1280);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final cache = LocalCacheDb.enMemoria();
    final servicio = KioskoServicio();

    // El caché es E/S real: fuera de runAsync su future nunca se resuelve
    // bajo el reloj falso de las pruebas y la pantalla se queda cargando.
    await tester.runAsync(() async {
      await cache.iniciar();
      await cache.reemplazarDestinos([
        {
          'id': 1,
          'calle': 'Roble',
          'tipo': 'casa',
          'numero': '10',
          'nombre': 'Roble 10',
        },
        {
          'id': 2,
          'calle': 'Pino',
          'tipo': 'casa',
          'numero': '20',
          'nombre': 'Pino 20',
        },
      ]);
      servicio.configurarOffline(_SinRed(), cache);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<KioskoServicio>.value(value: servicio),
            ChangeNotifierProvider<KioskoConfigNotifier>.value(
              value: _NotifierFake(servicio),
            ),
            ChangeNotifierProvider<ConnectivityService>.value(value: _SinRed()),
          ],
          child: const MaterialApp(home: CasaDestinoView()),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();
    addTearDown(() => cache.cerrar());

    // Se llegó al paso de calle con sus dos tarjetas.
    expect(find.text('Roble'), findsOneWidget);
    expect(find.text('Pino'), findsOneWidget);

    final tarjeta = tester.getRect(
      find
          .ancestor(of: find.text('Roble'), matching: find.byType(Container))
          .last,
    );
    expect(
      tarjeta.height,
      moreOrLessEquals(_altoTarjetaConMargen, epsilon: 0.5),
    );

    // El chip del ícono creció en proporción (56 -> 72) y sigue cuadrado; su
    // glifo y la flecha de la derecha van a la misma escala (28 -> 36).
    final chip = tester.getRect(
      find
          .ancestor(
            of: find.byIcon(Icons.signpost_outlined),
            matching: find.byType(Container),
          )
          .first,
    );
    expect(chip.width, moreOrLessEquals(72, epsilon: 0.5));
    expect(chip.height, moreOrLessEquals(chip.width, epsilon: 0.5));
    expect(
      tester.widget<Icon>(find.byIcon(Icons.signpost_outlined).first).size,
      36,
    );
    expect(
      tester.widget<Icon>(find.byIcon(Icons.chevron_right_rounded).first).size,
      36,
    );

    // Y lo que no se pidió cambiar sigue igual: el ancho (la tarjeta ocupa
    // todo el contenido, 800 - 42*2), el texto y el margen entre tarjetas.
    expect(tarjeta.width, moreOrLessEquals(716, epsilon: 0.5));
    expect(
      tester
          .renderObject<RenderParagraph>(find.text('Roble'))
          .text
          .style
          ?.fontSize,
      20,
    );
    // Las tarjetas van pegadas una tras otra (su caja ya incluye el margen),
    // así que de un arranque al siguiente hay exactamente un alto de
    // tarjeta: si alguien cambiara el margen, esta cuenta se rompe. Van
    // ordenadas alfabéticamente, de ahí el valor absoluto en vez de asumir
    // cuál de las dos quedó arriba.
    final otra = tester.getRect(
      find
          .ancestor(of: find.text('Pino'), matching: find.byType(Container))
          .last,
    );
    expect(
      (otra.top - tarjeta.top).abs(),
      moreOrLessEquals(_altoTarjetaConMargen, epsilon: 0.5),
    );
    expect(find.byType(Presionable), findsWidgets);
  });
}
