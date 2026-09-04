import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kigo_salida/core/theme/kigo_design.dart';
import 'package:kigo_salida/features/activacion/views/activacion_view.dart';
import 'package:kigo_salida/features/salida/services/salida_servicio.dart';
import 'package:kigo_salida/features/salida/views/salir_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _activarModoInmersivo();
  runApp(const _RaizReiniciable());
}

// Oculta barra de estado y de navegación -- mismo tratamiento que el
// kiosko principal, pensado para correr como dispositivo dedicado de pared.
void _activarModoInmersivo() {
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
}

class _RaizReiniciable extends StatefulWidget {
  const _RaizReiniciable();

  @override
  State<_RaizReiniciable> createState() => _RaizReiniciableState();
}

class _RaizReiniciableState extends State<_RaizReiniciable> with WidgetsBindingObserver {
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
    if (state == AppLifecycleState.resumed) _activarModoInmersivo();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AUTOnomIA Salida',
      debugShowCheckedModeBanner: false,
      theme: KigoDesign.darkTheme,
      home: const _Raiz(),
    );
  }
}

/// Decide entre activación y la pantalla de salida según haya o no sesión
/// guardada -- mismo criterio que KioskoConfigNotifier.necesitaActivacion en
/// el kiosko principal, sin la capa de config/SSE que este dispositivo no
/// necesita (no tiene pipeline configurable: solo hace una cosa).
class _Raiz extends StatefulWidget {
  const _Raiz();

  @override
  State<_Raiz> createState() => _RaizState();
}

class _RaizState extends State<_Raiz> {
  bool? _activado;

  @override
  void initState() {
    super.initState();
    _verificarSesion();
  }

  Future<void> _verificarSesion() async {
    final hay = await SalidaServicio().haySesion();
    if (mounted) setState(() => _activado = hay);
  }

  @override
  Widget build(BuildContext context) {
    if (_activado == null) {
      return Scaffold(
        backgroundColor: context.kBg,
        body: Center(child: CircularProgressIndicator(color: KigoDesign.brand)),
      );
    }
    if (!_activado!) {
      return ActivacionView(onActivado: () => setState(() => _activado = true));
    }
    return const SalirView();
  }
}
