import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../../../models/ine_ocr_model.dart';
import '../../../../services/detector_ine_servicio.dart';
import '../../../../theme/app_theme.dart';

/// Primer paso del wizard de identidad: captura la INE con la cámara y
/// corre el OCR on-device (mismo motor que el kiosko) para extraer CURP y
/// nombre. Ver spec 2026-08-17-kigo-app-rediseno-design.md §10.
class StepEscanearIne extends StatefulWidget {
  final void Function(IneOcrResult resultado) onEscaneado;
  const StepEscanearIne({super.key, required this.onEscaneado});

  @override
  State<StepEscanearIne> createState() => _StepEscanearIneState();
}

class _StepEscanearIneState extends State<StepEscanearIne> {
  CameraController? _controller;
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
      _controller = CameraController(camaras.first, ResolutionPreset.high, enableAudio: false);
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
      final resultado = await DetectorIneServicio().analizarIne(foto.path);
      widget.onEscaneado(resultado);
    } catch (_) {
      setState(() => _error = 'No se pudo capturar la foto, intenta de nuevo');
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
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
            width: MediaQuery.of(context).size.width * 0.85,
            height: MediaQuery.of(context).size.width * 0.85 * 0.63,
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.primaryOrange, width: 3),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const Positioned(
          top: 24,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              'Encuadra tu INE dentro del recuadro',
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
