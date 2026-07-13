import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Importacion los servicios del sistema
import 'package:kigo_kiosco/features/welcome/viewmodels/welcome_viewmodel.dart';
import 'package:kigo_kiosco/features/welcome/views/welcome_view.dart';

void main() {
  //es para poder comunicarnos con el sistema nativo antes de lanzar la app
  WidgetsFlutterBinding.ensureInitialized();

  // Activa el modo inmersivo/Pantalla completa
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const KigoApp());
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
      home: WelcomeView(
        //vista principal del usuario
        viewModel: WelcomeViewModel(),
      ),
    );
  }
}