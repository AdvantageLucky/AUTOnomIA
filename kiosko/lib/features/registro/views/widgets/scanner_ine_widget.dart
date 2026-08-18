import 'dart:async';

import 'package:kigo_kiosco/core/theme/kigo_design.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:kigo_kiosco/features/registro/services/detector_servicio.dart';
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

  // Auto-captura: cada pocos segundos se toma una foto silenciosa y se sondea
  // con el OCR local; en cuanto aparece una CURP válida, la pantalla se cierra
  // sola con esa foto. El botón manual queda como respaldo.
  final DetectorServicio _detector = DetectorServicio();
  Timer? _autoTimer;
  bool _sondeando = false;
  bool _cerrando = false;

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
          _iniciarAutoCaptura();
        }
      } catch (e) {
        debugPrint("Error al inicializar la cámara: $e");
      }
    }
  }

  void _iniciarAutoCaptura() {
    _autoTimer?.cancel();
    _autoTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) => _sondearIne());
  }

  Future<void> _sondearIne() async {
    if (_sondeando || _cerrando) return;
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_controller!.value.isTakingPicture) return;

    _sondeando = true;
    try {
      final XFile foto = await _controller!.takePicture();
      final resultado = await _detector.analizarIne(foto.path);

      if (!mounted || _cerrando) return;
      if (resultado?.curp != null) {
        _cerrando = true;
        _autoTimer?.cancel();
        Navigator.pop(context, foto.path);
      }
    } catch (e) {
      // Falla transitoria (cámara ocupada, OCR sin texto): el siguiente tick reintenta.
      debugPrint("Sondeo de INE falló: $e");
    } finally {
      _sondeando = false;
    }
  }

  // Función para tomar la foto y mandarla a procesar
  Future<void> _tomarFotoYProcesar() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_cerrando) return;

    try {
      _autoTimer?.cancel();
      // Espera a que termine un sondeo en curso para no chocar con la cámara
      while (_sondeando) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      if (_cerrando || !mounted) return;

      // Captura la foto localmente
      final XFile foto = await _controller!.takePicture();

      if (mounted) {
        _cerrando = true;
        // Regresamos ÚNICAMENTE la ruta de la foto (String) a la vista principal
        Navigator.pop(context, foto.path);
      }
    } catch (e) {
      debugPrint("Error al capturar la foto: $e");
      _iniciarAutoCaptura(); // Reanuda el sondeo si la captura manual falló
    }
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
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
          // Aviso de detección automática
          Positioned(
            top: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(color: Colors.green, strokeWidth: 2),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Detección automática — mantén la INE dentro del recuadro',
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
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