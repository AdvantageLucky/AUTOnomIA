import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
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

  /// true entre la primera detección válida y la reconfirmación -- feedback
  /// visual (verde) de "ya casi, no muevas la INE" mientras se vuelve a
  /// tomar la foto para descartar que fue un frame suelto (documento
  /// retirándose o momentáneamente borroso).
  bool _confirmando = false;

  @override
  void initState() {
    super.initState();
    // Pedir el permiso durante la animación de transición desde el paso
    // anterior (OTP) hace que el diálogo del sistema se pierda o el
    // request se quede colgado en algunos Android -- un solo
    // addPostFrameCallback (~16ms) no alcanza a cubrir la animación de
    // cierre del teclado numérico del OTP (~250-300ms), que StepOtp ya
    // dispara antes de navegar aquí pero cuya cola puede seguir corriendo.
    // Mismo margen que el que ya se usa más abajo tras conceder el permiso
    // (antes de abrir la cámara), por la misma razón.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), _pedirPermisoEIniciar);
    });
  }

  Future<void> _pedirPermisoEIniciar() async {
    final resultado = await solicitarPermisoCamara();
    if (!mounted) return;
    setState(() => _permiso = resultado);
    if (resultado == ResultadoPermisoCamara.concedido) {
      // El diálogo del sistema pausa la Activity un instante -- abrir la
      // cámara en el mismo tick en que se resuelve el permiso se quedaba
      // colgado en algunos Android (CameraController.initialize() nunca
      // completaba ni tronaba, spinner infinito). Un respiro corto evita la
      // carrera; el timeout de abajo es la red de seguridad si aun así pasa.
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    if (mounted) setState(() => _error = null);
    // Un reintento (tras timeout o error) puede dejar un controller a medio
    // inicializar aferrado al hardware -- liberarlo antes de abrir uno
    // nuevo, o el segundo intento se queda esperando igual.
    final anterior = _controller;
    _controller = null;
    await anterior?.dispose();
    try {
      final camaras = await availableCameras();
      if (camaras.isEmpty) {
        setState(() => _error = AppLocalizations.t(context, 'ine_sin_camara'));
        return;
      }
      _controller = CameraController(camaras.first, ResolutionPreset.high, enableAudio: false);
      await _controller!.initialize().timeout(
        const Duration(seconds: 8),
        onTimeout: () => throw CameraException('timeout', 'La cámara no respondió'),
      );
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
      if (mounted) setState(() => _error = AppLocalizations.t(context, 'ine_error_iniciar_camara'));
    }
  }

  void _iniciarAutoCaptura() {
    _autoTimer?.cancel();
    _autoTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
      _sondeoAutomatico();
    });
  }

  Future<void> _sondeoAutomatico() async {
    if (_sondeando || _cerrando || _confirmando) return;
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
      try { File(foto.path).deleteSync(); } catch (_) {}

      if (resultado.curp != null) {
        await _confirmarYReintentar();
      }
    } catch (e) {
      // Falla transitoria (cámara ocupada, OCR sin texto): el siguiente tick reintenta.
    } finally {
      _sondeando = false;
    }
  }

  /// Primera detección válida -> pausa visible (verde) -> se vuelve a tomar
  /// la foto y a correr el OCR antes de avanzar. Sin esto, un solo frame
  /// afortunado (documento a medio acomodar, o a medio retirarse) bastaba
  /// para avanzar con datos que un instante después ya no eran legibles.
  Future<void> _confirmarYReintentar() async {
    _autoTimer?.cancel();
    if (!mounted) return;
    setState(() => _confirmando = true);

    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted || _cerrando) return;

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      setState(() => _confirmando = false);
      _iniciarAutoCaptura();
      return;
    }

    try {
      final foto = await controller.takePicture();
      final resultado = await _detector.analizarIne(foto.path);

      if (!mounted || _cerrando) {
        try { File(foto.path).deleteSync(); } catch (_) {}
        return;
      }

      if (resultado.curp != null) {
        _cerrando = true;
        widget.onEscaneado(resultado);
      } else {
        // Se movió o se puso borrosa entre la primera detección y ahora --
        // se descarta y se reanuda el sondeo en vez de avanzar con datos
        // que ya no son confiables.
        try { File(foto.path).deleteSync(); } catch (_) {}
        setState(() => _confirmando = false);
        _iniciarAutoCaptura();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _confirmando = false);
        _iniciarAutoCaptura();
      }
    }
  }

  Future<void> _capturar() async {
    if (_controller == null || !_controller!.value.isInitialized || _procesando || _cerrando || _confirmando) return;
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
      setState(() => _error = AppLocalizations.t(context, 'ine_error_capturar'));
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _initCamera,
                      child: Text(AppLocalizations.t(context, 'retry')),
                    ),
                  ],
                ),
              )
            : const CircularProgressIndicator(),
      );
    }

    final colorGuia = _confirmando ? AppTheme.success : AppTheme.primaryOrange;

    return Stack(
      children: [
        Positioned.fill(child: CameraPreview(_controller!)),
        Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: MediaQuery.of(context).size.width * 0.85,
            height: MediaQuery.of(context).size.width * 0.85 * 0.63,
            decoration: BoxDecoration(
              border: Border.all(color: colorGuia, width: 3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _confirmando
                ? null
                : const CheckpointSweep(borderRadius: BorderRadius.all(Radius.circular(9))),
          ),
        ),
        Positioned(
          top: 24,
          left: 16,
          right: 16,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: _confirmando
                    ? AppTheme.success.withValues(alpha: 0.92)
                    : Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_confirmando) ...[
                    const Icon(Icons.check_circle, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        AppLocalizations.t(context, 'ine_detectada_confirmando'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(color: AppTheme.primaryOrange, strokeWidth: 2),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        AppLocalizations.t(context, 'encuadra_ine_detectando'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
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
