import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:kigo_kiosco/core/notifiers/kiosko_config_notifier.dart';
import 'package:kigo_kiosco/features/registro/services/kiosko_servicio.dart';
import 'package:kigo_kiosco/features/welcome/viewmodels/welcome_viewmodel.dart';
import 'package:kigo_kiosco/features/welcome/views/welcome_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

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

class KigoApp extends StatelessWidget {
  const KigoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kigo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Arial',
        useMaterial3: true,
      ),
      home: Consumer<KioskoConfigNotifier>(
        builder: (context, cfg, _) {
          if (cfg.cargando) return const _SplashScreen();
          return WelcomeView(viewModel: WelcomeViewModel());
        },
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF171313),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'K',
              style: TextStyle(
                color: Color(0xFFFF542F),
                fontSize: 72,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 32),
            CircularProgressIndicator(
              color: Color(0xFFFF542F),
              strokeWidth: 2.5,
            ),
          ],
        ),
      ),
    );
  }
}
