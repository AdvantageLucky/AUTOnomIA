import 'package:kigo_kiosco/core/theme/kigo_design.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'consent_dialog.dart';

class EscaneoInePage extends StatefulWidget {
  const EscaneoInePage({super.key});

  @override
  State<EscaneoInePage> createState() => _EscaneoInePageState();
}

class _EscaneoInePageState extends State<EscaneoInePage> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Pide consentimiento antes de activar la cámara; solo la inicializa si acepta
    WidgetsBinding.instance.addPostFrameCallback((_) => _solicitarConsentimiento());
  }

  Future<void> _solicitarConsentimiento() async {
    final bool aceptado = await mostrarConsentimientoCamara(context);

    if (!mounted) return;

    if (aceptado) {
      _initCamera();
    } else {
      Navigator.pop(context); // El usuario presionó "Regresar"
    }
  }

  // Inicializa la cámara trasera del dispositivo
  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      // Seleccionamos la cámara trasera (index 0 usualmente)
      _controller = CameraController(
        _cameras![0],
        ResolutionPreset.high, // Buena resolución para que el OCR no falle
        enableAudio: false,    // Apagamos el audio ya que solo queremos foto
      );

      try {
        await _controller!.initialize();
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      } catch (e) {
        debugPrint("Error al inicializar la cámara: $e");
      }
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
      return const Scaffold(
        backgroundColor: KigoDesign.bgDark,
        body: Center(child: CircularProgressIndicator(color: Color(0xFFFF542F))),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: KigoDesign.bgDark,
        title: const Text("Apunta a tu INE", style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context), // Botón físico/virtual para regresar si cancela
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CameraPreview(_controller!),
          ),
          // Tu recuadro verde guía...
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              height: MediaQuery.of(context).size.width * 0.85 * 0.63,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          // Botón de captura
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                backgroundColor: const Color(0xFFFF542F), // Usando tu naranja de Kigo
                onPressed: _tomarFotoYProcesar, // Ahora sí responderá al tap
                child: const Icon(Icons.camera_alt, color: Colors.white),
              ),
            ),
          )
        ],
      ),
    );
  }
}