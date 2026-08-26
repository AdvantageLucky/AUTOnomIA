import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:kigo_kiosco/core/models/kiosko_config.dart';
import 'package:kigo_kiosco/core/notifiers/kiosko_config_notifier.dart';
import 'package:kigo_kiosco/core/routing/observador_rutas.dart';
import 'package:kigo_kiosco/core/widgets/pantalla_error.dart';
import 'package:kigo_kiosco/core/widgets/sonda_diagnostico.dart';
import 'package:kigo_kiosco/core/theme/kigo_design.dart';
import 'package:kigo_kiosco/features/activacion/views/activacion_view.dart';
import 'package:kigo_kiosco/features/registro/services/kiosko_servicio.dart';
import 'package:kigo_kiosco/features/welcome/viewmodels/qr_scanner_viewmodel.dart';
import 'package:kigo_kiosco/features/welcome/viewmodels/welcome_viewmodel.dart';
import 'package:kigo_kiosco/features/welcome/views/qr_scanner_view.dart';
import 'package:kigo_kiosco/features/welcome/views/welcome_view.dart';
import 'package:kigo_kiosco/l10n/app_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  _instalarReporteDeErrores();
  _activarModoInmersivo();

  final servicio = KioskoServicio();
  final configNotifier = KioskoConfigNotifier(servicio);

  runApp(MultiProvider(
    providers: [
      Provider<KioskoServicio>.value(value: servicio),
      ChangeNotifierProvider<KioskoConfigNotifier>.value(value: configNotifier),
    ],
    child: const _RaizReiniciable(),
  ));

  // Se inicializa después de runApp para que el splash ya sea visible
  configNotifier.inicializar();
}

/// Deja los errores en pantalla en vez de la pantalla gris de release.
///
/// Sin esto, cualquier excepción de build o de layout se ve desde fuera como
/// que la app se congeló: el último cuadro sigue ahí, la textura de la cámara
/// se sigue componiendo sola, y nada responde al tacto.
void _instalarReporteDeErrores() {
  ErrorWidget.builder = (detalles) => PantallaError(
        mensaje: detalles.exceptionAsString(),
        detalle: detalles.stack?.toString(),
      );

  final manejadorPrevio = FlutterError.onError;
  FlutterError.onError = (detalles) {
    final texto = detalles.exceptionAsString();
    // Escribir el notifier a media construcción marca sucia la sonda que lo
    // escucha, y Flutter aborta con "Build scheduled during frame". Ese error
    // secundario tapa por completo al de verdad — un overflow, una assertion
    // de layout — y deja la app en un bucle de reconstrucción. Si estamos
    // dentro del cuadro, se apunta para el final.
    final fase = SchedulerBinding.instance.schedulerPhase;
    if (fase == SchedulerPhase.idle ||
        fase == SchedulerPhase.postFrameCallbacks) {
      ultimoError.value = texto;
    } else {
      SchedulerBinding.instance.addPostFrameCallback(
        (_) => ultimoError.value = texto,
      );
    }
    manejadorPrevio?.call(detalles);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    ultimoError.value = error.toString();
    debugPrint("[error asíncrono] $error");
    return true;
  };
}

/// Permite reconstruir el árbol entero desde la pantalla de error, sin tener
/// que matar el proceso ni reinstalar.
class _RaizReiniciable extends StatelessWidget {
  const _RaizReiniciable();


  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: generacionApp,
      builder: (context, generacion, _) =>
          KeyedSubtree(key: ValueKey(generacion), child: const KigoApp()),
    );
  }
}

// Oculta barra de estado y de navegación. Se vuelve a invocar en cada resume
// porque Android suele soltar el modo inmersivo al volver de segundo plano.
void _activarModoInmersivo() {
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
}

class KigoApp extends StatefulWidget {
  const KigoApp({super.key});

  @override
  State<KigoApp> createState() => _KigoAppState();
}

class _KigoAppState extends State<KigoApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _activarModoInmersivo();
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Consumer<KioskoConfigNotifier>(
      builder: (context, cfg, _) {
        final esClaro = cfg.config.colorTema == KioskoColorTema.claro;
        final locale = Locale(cfg.config.idioma);

        return MaterialApp(
          title: 'Kigo',
          debugShowCheckedModeBanner: false,
          locale: locale,
          supportedLocales: const [Locale('es'), Locale('en')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: esClaro ? KigoDesign.lightTheme : KigoDesign.darkTheme,
          navigatorKey: navegadorKigo,
          navigatorObservers: [observadorDeRutas],
          // La sonda va por encima de TODAS las rutas, barreras modales
          // incluidas, y dentro de un IgnorePointer para no robar toques.
          builder: (context, child) => Stack(
            children: [
              ?child,
              const IgnorePointer(child: SondaDiagnostico()),
            ],
          ),
          home: Builder(builder: (context) {
            if (cfg.cargando) return const _SplashScreen();
            if (cfg.necesitaActivacion) {
              return ActivacionView(onActivado: () => cfg.reinicializar());
            }
            return QrScannerView(
              viewModel: QrScannerViewModel(),
              // Sin `Navigator.of(context)`: este closure se le pasa tambien a las
              // pantallas de escaneo que se crean después, y para entonces el
              // contexto de este Builder ya puede estar desactivado.
              onSinCodigo: () => navegadorKigo.currentState?.push(
                MaterialPageRoute(
                  builder: (_) => WelcomeView(viewModel: WelcomeViewModel()),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'K',
              style: TextStyle(
                color: KigoDesign.brand,
                fontSize: 72,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 32),
            CircularProgressIndicator(
              color: KigoDesign.brand,
              strokeWidth: 2.5,
            ),
          ],
        ),
      ),
    );
  }
}
