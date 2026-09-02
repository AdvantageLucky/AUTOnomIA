import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../../../models/ine_ocr_model.dart';
import '../../../../services/camera_permission_servicio.dart';
import '../../../../services/detector_ine_servicio.dart';
import '../../../../theme/app_theme.dart';
import 'checkpoint_sweep.dart';
import 'permiso_camara_widget.dart';

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
  ResultadoPermisoCamara? _permiso;

  // Sondeo automático: cada 1.2s se toma una foto silenciosa y se corre el
  // OCR; en cuanto aparece una CURP válida, se avanza sola con esa foto. El
  // botón manual queda como respaldo si el documento no coopera (mala luz,
  // reflejo, lente de foco fijo).
  final _detector = DetectorIneServicio();
  Timer? _autoTimer;
  bool _sondeando = false;
  bool _cerrando = false;

  @override
  void initState() {
    super.initState();
    _pedirPermisoEIniciar();
  }

  Future<void> _pedirPermisoEIniciar() async {
    final resultado = await solicitarPermisoCamara();
    if (!mounted) return;
    setState(() => _permiso = resultado);
    if (resultado == ResultadoPermisoCamara.concedido) {
      _initCamera();
    }
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
      // El flash automático contra el plástico laminado de la INE genera
      // un reflejo que arruina el OCR — se apaga explícitamente.
      await _controller!.setFlashMode(FlashMode.off);

      // El recuadro guía está centrado, así que ahí es donde debe enfocar.
      // No todos los lentes soportan foco por punto (algunos son de foco
      // fijo) -- si falla, se ignora y se sigue con el foco automático que
      // ya trae el controller por default.
      try {
        await _controller!.setFocusMode(FocusMode.auto);
        await _controller!.setFocusPoint(const Offset(0.5, 0.5));
      } catch (_) {}

      if (mounted) setState(() {});
      _iniciarAutoCaptura();
    } catch (e) {
      if (mounted) setState(() => _error = 'No se pudo iniciar la cámara');
    }
  }

  void _iniciarAutoCaptura() {
    _autoTimer?.cancel();
    _autoTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
      _sondeoAutomatico();
    });
  }

  Future<void> _sondeoAutomatico() async {
    if (_sondeando || _cerrando) return;
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || controller.value.isTakingPicture) {
      return;
    }

    _sondeando = true;
    XFile? foto;
    try {
      foto = await controller.takePicture();
      final resultado = await _detector.analizarIne(foto.path);

      if (!mounted || _cerrando) {
        try { File(foto.path).deleteSync(); } catch (_) {}
        return;
      }

      if (resultado.curp != null) {
        _cerrando = true;
        _autoTimer?.cancel();
        widget.onEscaneado(resultado);
      } else {
        try { File(foto.path).deleteSync(); } catch (_) {}
      }
    } catch (e) {
      // Falla transitoria (cámara ocupada, OCR sin texto): el siguiente tick reintenta.
    } finally {
      _sondeando = false;
    }
  }

  Future<void> _capturar() async {
    if (_controller == null || !_controller!.value.isInitialized || _procesando || _cerrando) return;
    _autoTimer?.cancel();
    setState(() {
      _procesando = true;
      _error = null;
    });
    try {
      final foto = await _controller!.takePicture();
      final resultado = await _detector.analizarIne(foto.path);
      _cerrando = true;
      widget.onEscaneado(resultado);
    } catch (_) {
      setState(() => _error = 'No se pudo capturar la foto, intenta de nuevo');
      _iniciarAutoCaptura();
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_permiso == ResultadoPermisoCamara.denegado || _permiso == ResultadoPermisoCamara.denegadoPermanente) {
      return Center(
        child: PermisoCamaraDenegado(
          permanente: _permiso == ResultadoPermisoCamara.denegadoPermanente,
          onReintentar: _pedirPermisoEIniciar,
        ),
      );
    }

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
            child: const CheckpointSweep(borderRadius: BorderRadius.all(Radius.circular(9))),
          ),
        ),
        Positioned(
          top: 24,
          left: 16,
          right: 16,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(color: AppTheme.primaryOrange, strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  const Flexible(
                    child: Text(
                      'Encuadra tu INE dentro del recuadro, detectando…',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_error != null)
          Positioned(
            top: 70,
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
