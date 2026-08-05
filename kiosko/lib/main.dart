import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Importacion los servicios del sistema
import 'package:kigo_kiosco/features/welcome/viewmodels/welcome_viewmodel.dart';
import 'package:kigo_kiosco/features/welcome/views/welcome_view.dart';

void main() {
  //es para poder comunicarnos con el sistema nativo antes de lanzar la app
  WidgetsFlutterBinding.ensureInitialized();

  _activarModoInmersivo();

  runApp(const KigoApp());
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
    return MaterialApp(
      title: 'Kigo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Arial',
        useMaterial3: true,
      ),
      home: WelcomeView(
        //vista principal del usuario
        viewModel: WelcomeViewModel(),
      ),
    );
  }
}