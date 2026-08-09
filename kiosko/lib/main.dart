import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:kigo_kiosco/core/models/kiosko_config.dart';
import 'package:kigo_kiosco/core/notifiers/kiosko_config_notifier.dart';
import 'package:kigo_kiosco/core/theme/kigo_design.dart';
import 'package:kigo_kiosco/features/activacion/views/activacion_view.dart';
import 'package:kigo_kiosco/features/registro/services/kiosko_servicio.dart';
import 'package:kigo_kiosco/features/welcome/viewmodels/welcome_viewmodel.dart';
import 'package:kigo_kiosco/features/welcome/views/welcome_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  _activarModoInmersivo();

  final servicio = KioskoServicio();
  final configNotifier = KioskoConfigNotifier(servicio);

  runApp(MultiProvider(
    providers: [
      Provider<KioskoServicio>.value(value: servicio),
      ChangeNotifierProvider<KioskoConfigNotifier>.value(value: configNotifier),
    ],
    child: const KigoApp(),
  ));

  // Se inicializa después de runApp para que el splash ya sea visible
  configNotifier.inicializar();
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
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: esClaro ? KigoDesign.lightTheme : KigoDesign.darkTheme,
          home: Builder(builder: (context) {
            if (cfg.cargando) return const _SplashScreen();
            if (cfg.necesitaActivacion) {
              return ActivacionView(onActivado: () => cfg.reinicializar());
            }
            return WelcomeView(viewModel: WelcomeViewModel());
          }),
        );
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

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
