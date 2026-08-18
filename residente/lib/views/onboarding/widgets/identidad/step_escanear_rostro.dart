import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../../../services/reconocimiento_facial_servicio.dart';
import '../../../../theme/app_theme.dart';

/// Tercer y último paso del wizard de identidad: captura el rostro y
/// calcula su embedding on-device (MobileFaceNet, mismo modelo del
/// kiosko). Si no se detecta un rostro válido, se puede reintentar.
class StepEscanearRostro extends StatefulWidget {
  final void Function(String pathFoto, List<double> embedding) onCapturado;
  const StepEscanearRostro({super.key, required this.onCapturado});

  @override
  State<StepEscanearRostro> createState() => _StepEscanearRostroState();
}

class _StepEscanearRostroState extends State<StepEscanearRostro> {
  CameraController? _controller;
  final _servicio = ReconocimientoFacialServicio();
  bool _procesando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final camaras = await availableCameras();
      if (camaras.isEmpty) {
        setState(() => _error = 'No se encontró ninguna cámara en este dispositivo');
        return;
      }
      final frontal = camaras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => camaras.first,
      );
      _controller = CameraController(frontal, ResolutionPreset.high, enableAudio: false);
      await _controller!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) setState(() => _error = 'No se pudo iniciar la cámara');
    }
  }

  Future<void> _capturar() async {
    if (_controller == null || !_controller!.value.isInitialized || _procesando) return;
    setState(() {
      _procesando = true;
      _error = null;
    });
    try {
      final foto = await _controller!.takePicture();
      final embedding = await _servicio.calcularEmbedding(foto.path);
      if (embedding == null) {
        setState(() => _error = 'No detectamos tu rostro con claridad, intenta de nuevo');
        return;
      }
      widget.onCapturado(foto.path, embedding);
    } catch (_) {
      setState(() => _error = 'No se pudo capturar la foto, intenta de nuevo');
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _servicio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Center(
        child: _error != null
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!, textAlign: TextAlign.center),
              )
            : const CircularProgressIndicator(),
      );
    }

    return Stack(
      children: [
        Positioned.fill(child: CameraPreview(_controller!)),
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.6,
            height: MediaQuery.of(context).size.width * 0.6,
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.primaryOrange, width: 3),
              shape: BoxShape.circle,
            ),
          ),
        ),
        const Positioned(
          top: 24,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              'Encuadra tu rostro dentro del círculo',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        if (_error != null)
          Positioned(
            top: 60,
            left: 24,
            right: 24,
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.error, fontWeight: FontWeight.w600),
            ),
          ),
        Positioned(
          bottom: 32,
          left: 0,
          right: 0,
          child: Center(
            child: FloatingActionButton(
              backgroundColor: AppTheme.primaryOrange,
              onPressed: _procesando ? null : _capturar,
              child: _procesando
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                    )
                  : const Icon(Icons.camera_alt, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
