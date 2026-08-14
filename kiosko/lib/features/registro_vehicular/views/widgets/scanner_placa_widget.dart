/* CAPTURA DE LA PLACA VEHICULAR */

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:kigo_kiosco/core/theme/kigo_design.dart';
import 'package:kigo_kiosco/features/registro/views/widgets/consent_dialog.dart';

/// Misma mecánica que [EscaneoInePage]: pide consentimiento, abre la cámara
/// trasera y devuelve la ruta de la foto. Lo que cambia es la guía en pantalla,
/// con la proporción de una placa (~2:1) en lugar de la de una credencial.
class EscaneoPlacaPage extends StatefulWidget {
  const EscaneoPlacaPage({super.key});

  @override
  State<EscaneoPlacaPage> createState() => _EscaneoPlacaPageState();
}

class _EscaneoPlacaPageState extends State<EscaneoPlacaPage> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _solicitarConsentimiento());
  }

  Future<void> _solicitarConsentimiento() async {
    final bool aceptado = await mostrarConsentimientoCamara(context);

    if (!mounted) return;

    if (aceptado) {
      _initCamera();
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras == null || _cameras!.isEmpty) return;

    // Cámara trasera: la placa se fotografía de frente al vehículo.
    _controller = CameraController(
      _cameras![0],
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      debugPrint('Error al inicializar la cámara: $e');
    }
  }

  Future<void> _tomarFotoYProcesar() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      final XFile foto = await _controller!.takePicture();
      if (mounted) Navigator.pop(context, foto.path);
    } catch (e) {
      debugPrint('Error al capturar la foto: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return const Scaffold(
        backgroundColor: KigoDesign.bgDark,
        body: Center(child: CircularProgressIndicator(color: KigoDesign.brand)),
      );
    }

    final anchoGuia = MediaQuery.of(context).size.width * 0.8;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: KigoDesign.bgDark,
        title: const Text('Apunta a la placa', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: CameraPreview(_controller!)),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: anchoGuia,
                  height: anchoGuia * 0.5, // proporción de una placa mexicana
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.green, width: 3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Encuadra la placa completa dentro del recuadro',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    shadows: [Shadow(color: Colors.black, blurRadius: 8)],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                backgroundColor: KigoDesign.brand,
                onPressed: _tomarFotoYProcesar,
                child: const Icon(Icons.camera_alt, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
