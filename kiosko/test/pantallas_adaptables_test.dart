// El kiosko se diseñó para un panel de 800x1280, pero ya se instala en
// tablets de otras medidas (y se prueba en teléfonos). Esta prueba monta
// cada pantalla en varios lienzos y exige lo mínimo para que sirva en
// cualquiera: que no reviente por desbordes y que el contenido quepa dentro
// de la pantalla.
//
// Es la red de seguridad de los arreglos de adaptabilidad: cuando alguien
// vuelva a clavar una medida fija que sólo cabe en 800x1280, aquí falla.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:kigo_kiosco/core/models/kiosko_config.dart';
import 'package:kigo_kiosco/core/models/score_ia_model.dart';
import 'package:kigo_kiosco/core/notifiers/kiosko_config_notifier.dart';
import 'package:kigo_kiosco/core/services/connectivity_service.dart';
import 'package:kigo_kiosco/core/services/consentimiento_servicio.dart';
import 'package:kigo_kiosco/core/widgets/asistencia_urgente_sheet.dart';
import 'package:kigo_kiosco/core/widgets/faq_offline_sheet.dart';
import 'package:kigo_kiosco/core/widgets/menu_ayuda_sheet.dart';
import 'package:kigo_kiosco/core/widgets/pin_operador_sheet.dart';
import 'package:kigo_kiosco/features/registro/views/widgets/consent_dialog.dart';
import 'package:kigo_kiosco/core/theme/kigo_design.dart';
import 'package:kigo_kiosco/features/registro/models/user_registration_model.dart';
import 'package:kigo_kiosco/features/registro/services/kiosko_servicio.dart';
import 'package:kigo_kiosco/features/registro/views/analisis_ia_view.dart';
import 'package:kigo_kiosco/features/residente/views/residente_acceso_view.dart';
import 'package:kigo_kiosco/features/welcome/viewmodels/qr_scanner_viewmodel.dart';
import 'package:kigo_kiosco/features/welcome/views/qr_scanner_view.dart';
import 'package:kigo_kiosco/features/registro/views/casa_destino_view.dart';
import 'package:kigo_kiosco/features/registro/views/motivo_view.dart';
import 'package:kigo_kiosco/features/registro/views/resumen_solicitud_view.dart';
import 'package:kigo_kiosco/features/registro/views/touch_register_view.dart';
import 'package:kigo_kiosco/features/registro_vehicular/viewmodels/vehicular_register_viewmodel.dart';
import 'package:kigo_kiosco/features/registro_vehicular/views/escaneo_placa_view.dart';
import 'package:kigo_kiosco/features/registro_vehicular/views/vehicular_register_view.dart';
import 'package:kigo_kiosco/features/activacion/views/activacion_view.dart';
import 'package:kigo_kiosco/features/welcome/viewmodels/persona_qr_result_viewmodel.dart';
import 'package:kigo_kiosco/features/welcome/viewmodels/qr_result_viewmodel.dart';
import 'package:kigo_kiosco/features/welcome/views/persona_qr_result_view.dart';
import 'package:kigo_kiosco/features/welcome/views/qr_result_view.dart';
import 'package:kigo_kiosco/features/registro_vehicular/views/confirmar_placa_view.dart';
import 'package:kigo_kiosco/features/welcome/viewmodels/operator_exit_viewmodel.dart';
import 'package:kigo_kiosco/features/welcome/viewmodels/resident_pin_viewmodel.dart';
import 'package:kigo_kiosco/features/welcome/viewmodels/resident_welcome_viewmodel.dart';
import 'package:kigo_kiosco/features/welcome/viewmodels/welcome_viewmodel.dart';
import 'package:kigo_kiosco/features/welcome/views/operator_exit_pin_view.dart';
import 'package:kigo_kiosco/features/welcome/views/resident_pin_view.dart';
import 'package:kigo_kiosco/features/welcome/views/resident_welcome_view.dart';
import 'package:kigo_kiosco/features/welcome/views/welcome_view.dart';

class _NotifierFake extends KioskoConfigNotifier {
  _NotifierFake(super.servicio);
  @override
  KioskoConfig get config =>
      KioskoConfig.fromJson(const {'mensaje_bienvenida': 'BIENVENIDO A FEPRO 2026'});
}

/// El abanico de pantallas donde puede acabar instalado: el panel para el
/// que se diseñó, tablets de 7"/10" en las dos orientaciones y teléfonos
/// (donde se prueba a mano).
const _lienzos = <String, Size>{
  'panel 800x1280': Size(800, 1280),
  'tablet 7" vertical': Size(600, 1024),
  'tablet 10" horizontal': Size(1280, 800),
  'panel grande': Size(1200, 1920),
  'telefono': Size(411, 891),
  'telefono chico': Size(320, 640),
};

Future<void> _montar(WidgetTester tester, Size lienzo, Widget pantalla) async {
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
    child: MaterialApp(theme: KigoDesign.darkTheme, home: pantalla),
  ));
  await tester.pump();
}

ScoreIaModel _score() => ScoreIaModel(
      confianzaPct: 72,
      nivelConfianza: 'media',
      factores: [
        FactorScoreModel(
          clave: 'ine',
          etiqueta: 'Identificación legible',
          detalle: 'La INE se leyó completa',
          impacto: 20,
          tipo: 'positivo',
        ),
      ],
      recomendaciones: const ['Confirmar el destino con el residente'],
      generadoPorIA: false,
    );

UserRegistrationModel _datos() => UserRegistrationModel(
      nombreCompleto: 'Visitante de Prueba',
      casaDestino: 'PRINCIPAL · Casa 101',
      placa: 'ABC-1234',
    )..motivo = 'Entrega de paquetería';

/// Todas las pantallas del kiosko. Las de cámara se montan igual: el plugin
/// no existe en pruebas, la vista cae en su placeholder y el layout que se
/// mide alrededor es el mismo.
Map<String, Widget Function()> _pantallas() => {
      'bienvenida': () => WelcomeView(viewModel: WelcomeViewModel()),
      'motivo': () => const MotivoView(),
      'casa destino': () => const CasaDestinoView(),
      'resumen de solicitud': () =>
          ResumenSolicitudView(registrationData: _datos()),
      'confirmar placa': () => const ConfirmarPlacaView(placaLeida: 'ABC1234'),
      'PIN de residente': () => ResidentPinView(viewModel: ResidentPinViewModel()),
      'PIN de operador': () =>
          OperatorExitPinView(viewModel: OperatorExitViewModel()),
      'bienvenida de residente': () => ResidentWelcomeView(
            viewModel: ResidentWelcomeViewModel(
              nombre: 'María de la Luz Hernández Guzmán',
              casaDestino: 'PRINCIPAL · Casa 101',
            ),
          ),
      'escaner QR (entrada)': () => QrScannerView(
            viewModel: QrScannerViewModel(),
            onSinCodigo: () {},
          ),
      'acceso de residente': () => const ResidenteAccesoView(),
      'registro tactil': () => const TouchRegisterView(),
      'registro vehicular': () => VehicularRegisterView(
            viewModel: VehicularRegisterViewModel(KioskoConfig.fromJson(const {})),
          ),
      'escaneo de placa': () => const EscaneoPlacaView(),
      'activacion del equipo': () => ActivacionView(onActivado: () {}),
      'resultado de QR': () => QrResultView(viewModel: QrResultViewModel(token: 'tok')),
      'resultado de QR personal': () => PersonaQrResultView(
            viewModel: PersonaQrResultViewModel(qrValue: 'persona:firma'),
          ),
      'analisis de IA': () => AnalisisIaView(
            score: _score(),
            resumen: 'El visitante trae identificación legible y destino conocido.',
          ),
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // El almacenamiento seguro y la síntesis de voz no existen en el
    // entorno de pruebas: sin estos mocks la pantalla revienta por el
    // canal, no por el layout, que es lo que se está midiendo.
    const secure = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secure, (llamada) async {
      if (llamada.method == 'read') return '2026-01-01T00:00:00.000';
      return null;
    });
    const tts = MethodChannel('flutter_tts');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(tts, (_) async => 1);

    // El consentimiento ya dado: las pantallas de captura abrirían su
    // diálogo (con cuenta regresiva) encima de lo que se quiere medir.
    ConsentimientoServicio.otorgar();
  });

  tearDown(ConsentimientoServicio.reiniciar);

  // Las hojas y diálogos que se abren encima de las pantallas: el visitante
  // los ve del mismo tamaño que el resto, y son los que más fácil se salen
  // de una pantalla baja (llevan lista y botones apilados).
  final sobrepuestos = <String, Future<void> Function(BuildContext)>{
    'asistencia urgente': (c) => mostrarAsistenciaUrgente(
          c,
          telefonoContacto: '+52 55 1234 5678',
          offline: false,
          onSolicitar: () {},
        ),
    'menu de ayuda': (c) => mostrarMenuAyuda(c, telefonoContacto: '+52 55 1234 5678'),
    'FAQ sin conexion': mostrarFaqOffline,
    'PIN de operador (hoja)': pedirPinOperador,
    'consentimiento de camara': mostrarConsentimientoCamara,
  };

  sobrepuestos.forEach((nombre, abrir) {
    _lienzos.forEach((etiqueta, lienzo) {
      testWidgets('$nombre no desborda en $etiqueta', (tester) async {
        late BuildContext ctx;
        await _montar(
          tester,
          lienzo,
          Builder(builder: (context) {
            ctx = context;
            return const Scaffold();
          }),
        );

        abrir(ctx);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // El diálogo de consentimiento se acepta solo a los 6s; drenarlo
        // evita que el harness reporte su cuenta regresiva como fuga.
        await tester.pump(const Duration(seconds: 7));
      });
    });
  });

  _pantallas().forEach((nombre, construir) {
    _lienzos.forEach((etiqueta, lienzo) {
      testWidgets('$nombre no desborda en $etiqueta', (tester) async {
        await _montar(tester, lienzo, construir());
        expect(tester.takeException(), isNull);

        // El mock del lector de placas deja un temporizador de 5s vivo y el
        // harness lo reporta como fuga al terminar. Se drena aquí, ya
        // medido el layout.
        await tester.pump(const Duration(seconds: 6));
      });
    });
  });
}
