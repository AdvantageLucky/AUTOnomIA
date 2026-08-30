import 'package:kigo_kiosco/core/theme/kigo_design.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:kigo_kiosco/core/services/camara_kiosko.dart';
import 'package:kigo_kiosco/core/services/consentimiento_servicio.dart';
import 'package:kigo_kiosco/core/widgets/marco_guia_camara.dart';
import 'package:kigo_kiosco/core/widgets/vista_previa_camara.dart';
import 'consent_dialog.dart';
import 'package:kigo_kiosco/l10n/app_localizations.dart';

class EscaneoRostro extends StatefulWidget {
  const EscaneoRostro({super.key});

  @override
  State<EscaneoRostro> createState() => _EscaneoRostroState();
}

class _EscaneoRostroState extends State<EscaneoRostro> {
  CameraController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Pide consentimiento antes de activar la cámara; solo la inicializa si acepta
    WidgetsBinding.instance.addPostFrameCallback((_) => _solicitarConsentimiento());
  }

  Future<void> _solicitarConsentimiento() async {
    // Ya se pidió una vez para esta visita, en la pantalla de entrada
    // (el 100% de los visitantes pasa por ahí antes de llegar aquí).
    if (ConsentimientoServicio.otorgado) {
      _initCamera();
      return;
    }

    final bool aceptado = await mostrarConsentimientoCamara(context);

    if (!mounted) return;

    if (aceptado) {
      ConsentimientoServicio.otorgar();
      _initCamera();
    } else {
      Navigator.pop(context); // El usuario presionó "Regresar"
    }
  }

  // Inicializa la cámara de rostro con los ajustes propios del hardware.
  // En el kiosko la lente correcta y la resolución vienen de AjustesCamara:
  // pedir `high` a un sensor de 2MP hace que la vista previa se congele.
  Future<void> _initCamera() async {
    try {
      final camara = await CamaraKiosko.paraRostro();
      final controller = CamaraKiosko.controlador(
        camara,
        AjustesCamara.resolucionRostro,
      );

      await CamaraKiosko.inicializar(controller);

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint("Error al inicializar la cámara: $e");
    }
  }

  // Función para tomar la foto y mandarla a procesar
  Future<void> _tomarFotoYProcesar() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      // Captura la foto localmente
      final XFile foto = await _controller!.takePicture();
      
      if (mounted) {
        // Regresamos ÚNICAMENTE la ruta de la foto (String) a la vista principal
        Navigator.pop(context, foto.path);
      }
    } catch (e) {
      debugPrint("Error al capturar la foto: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose(); // Muy importante liberar la cámara al salir
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return Scaffold(
        backgroundColor: context.kBg,
        body: Center(child: CircularProgressIndicator(color: KigoDesign.brand)),
      );
    }

    final size = MediaQuery.of(context).size;
    final ovalW = size.width * 0.72;
    final ovalH = ovalW * 1.25;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.kBg,
        title: Text(AppLocalizations.t(context, 'apunta_a_tu_rostro'), style: TextStyle(color: context.kTextPrimary)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.kTextPrimary),
          onPressed: () => Navigator.pop(context), // Botón físico/virtual para regresar
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: VistaPreviaCamara(_controller!),
          ),

          // Overlay opaco con recorte oval + guía — compartido con
          // residente_acceso_view.dart (mismo tratamiento visual).
          Positioned.fill(
            child: MarcoGuiaCamara(ancho: ovalW, alto: ovalH),
          ),

          // Instrucción
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Text(
              AppLocalizations.t(context, 'centra_rostro_ovalo'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),

          // Botón de captura
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                backgroundColor: KigoDesign.brand, // naranja de Kigo
                onPressed: _tomarFotoYProcesar,
                child: const Icon(Icons.camera_alt, color: Colors.white),
              ),
            ),
          )
        ],
      ),
    );
  }
}

