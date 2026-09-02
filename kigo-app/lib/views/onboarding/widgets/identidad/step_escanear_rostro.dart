import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/camera_permission_servicio.dart';
import '../../../../services/face_detector_servicio.dart';
import '../../../../services/kigo_verify_servicio.dart';
import '../../../../services/reconocimiento_facial_servicio.dart';
import '../../../../theme/app_theme.dart';
import 'kigo_verify_webview_view.dart';
import 'marco_guia_camara.dart';
import 'permiso_camara_widget.dart';

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
  final _detector = FaceDetectorServicio();
  final _kigoVerify = KigoVerifyServicio();
  bool _procesando = false;
  bool _verificandoConKigo = false;
  String? _error;
  ResultadoPermisoCamara? _permiso;

  // Auto-detección: sondeo periódico con ML Kit (liviano); el embedding
  // (pesado, corre TFLite) solo se calcula una vez, sobre la foto ya
  // confirmada -- ver docstring de FaceDetectorServicio.
  Timer? _timerAutoScan;
  bool _sondeando = false;
  bool _rostroDetectado = false;
  bool _capturaFinalizada = false;

  /// Mismo margen que el kiosko: la primera detección puede ser mientras el
  /// usuario todavía se acomoda frente a la cámara.
  static const _deteccionesRequeridas = 2;
  int _deteccionesConsecutivas = 0;

  /// Tras 5 intentos fallidos de Kigo Verify en este paso, se oculta la
  /// opción y se fuerza el camino manual con la cámara propia.
  static const _maxIntentosKigo = 5;
  int _intentosKigoFallidos = 0;
  bool get _kigoDisponible => _intentosKigoFallidos < _maxIntentosKigo;

  @override
  void initState() {
    super.initState();
    // Mismo motivo que en step_escanear_ine: pedir el permiso durante la
    // transición de entrada a este paso puede dejar el request colgado.
    WidgetsBinding.instance.addPostFrameCallback((_) => _pedirPermisoEIniciar());
  }

  Future<void> _pedirPermisoEIniciar() async {
    final resultado = await solicitarPermisoCamara();
    if (!mounted) return;
    setState(() => _permiso = resultado);
    if (resultado == ResultadoPermisoCamara.concedido) {
      // Ver comentario equivalente en step_escanear_ine: abrir la cámara en
      // el mismo tick en que se resuelve el diálogo de permiso se quedaba
      // colgado en algunos Android.
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    if (mounted) setState(() => _error = null);
    final anterior = _controller;
    _controller = null;
    await anterior?.dispose();
    try {
      final camaras = await availableCameras();
      if (camaras.isEmpty) {
        setState(() => _error = AppLocalizations.t(context, 'ine_sin_camara'));
        return;
      }
      final frontal = camaras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => camaras.first,
      );
      _controller = CameraController(frontal, ResolutionPreset.high, enableAudio: false);
      await _controller!.initialize().timeout(
        const Duration(seconds: 8),
        onTimeout: () => throw CameraException('timeout', 'La cámara no respondió'),
      );
      await _controller!.setFlashMode(FlashMode.off);
      if (mounted) setState(() {});
      _iniciarAutoDeteccion();
    } catch (e) {
      if (mounted) setState(() => _error = AppLocalizations.t(context, 'ine_error_iniciar_camara'));
    }
  }

  void _iniciarAutoDeteccion() {
    _timerAutoScan?.cancel();
    _timerAutoScan = Timer.periodic(const Duration(milliseconds: 700), (_) {
      _intentarAutoCaptura();
    });
  }

  Future<void> _intentarAutoCaptura() async {
    if (_sondeando || _capturaFinalizada || _procesando || _verificandoConKigo) return;
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || controller.value.isTakingPicture) {
      return;
    }

    _sondeando = true;
    XFile? foto;
    try {
      foto = await controller.takePicture();
      final esValido = await _detector.tieneRostroValido(foto.path);

      if (!mounted) {
        try { File(foto.path).deleteSync(); } catch (_) {}
        return;
      }

      if (esValido && !_capturaFinalizada) {
        _deteccionesConsecutivas++;
        if (_deteccionesConsecutivas < _deteccionesRequeridas) {
          try { File(foto.path).deleteSync(); } catch (_) {}
          return;
        }
        await _confirmarCaptura(foto.path);
        return;
      } else {
        _deteccionesConsecutivas = 0;
        try { File(foto.path).deleteSync(); } catch (_) {}
      }
    } catch (e) {
      // Falla transitoria (cámara ocupada): el siguiente tick reintenta.
    } finally {
      _sondeando = false;
    }
  }

  Future<void> _confirmarCaptura(String pathFoto) async {
    _timerAutoScan?.cancel();
    setState(() {
      _rostroDetectado = true;
      _capturaFinalizada = true;
      _procesando = true;
    });

    // Breve pausa para que el usuario reciba la retroalimentación visual del
    // "detectado" antes de que la pantalla cambie.
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    final embedding = await _servicio.calcularEmbedding(pathFoto);
    if (!mounted) return;

    if (embedding == null) {
      // El sondeo (ML Kit) dio válido pero el recorte final falló -- reintenta.
      setState(() {
        _error = AppLocalizations.t(context, 'rostro_no_detectado_claridad');
        _rostroDetectado = false;
        _capturaFinalizada = false;
        _procesando = false;
        _deteccionesConsecutivas = 0;
      });
      _iniciarAutoDeteccion();
      return;
    }

    widget.onCapturado(pathFoto, embedding);
  }

  // Botón manual: toma la foto y la corre directo por el embedding, sin
  // esperar al sondeo automático.
  Future<void> _capturar() async {
    if (_controller == null || !_controller!.value.isInitialized || _procesando || _capturaFinalizada) return;
    _timerAutoScan?.cancel();
    setState(() {
      _procesando = true;
      _error = null;
    });
    try {
      final foto = await _controller!.takePicture();
      final embedding = await _servicio.calcularEmbedding(foto.path);
      if (embedding == null) {
        setState(() => _error = AppLocalizations.t(context, 'rostro_no_detectado_claridad'));
        _iniciarAutoDeteccion();
        return;
      }
      widget.onCapturado(foto.path, embedding);
    } catch (_) {
      setState(() => _error = AppLocalizations.t(context, 'ine_error_capturar'));
      _iniciarAutoDeteccion();
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _verificarConKigo() async {
    if (_procesando || _verificandoConKigo) return;
    _timerAutoScan?.cancel();
    setState(() {
      _verificandoConKigo = true;
      _error = null;
    });

    try {
      final enrollment = await _kigoVerify.iniciar();
      if (!mounted) return;

      await mostrarKigoVerifyWebview(context, enrollment.enrollmentUrl, enrollment.redirectUrl);
      if (!mounted) return;

      final resultado = await _esperarResultado(enrollment.enrollmentId);
      if (!mounted) return;
      if (resultado == null) {
        _registrarIntentoKigoFallido(AppLocalizations.t(context, 'kigo_verify_fallo'));
        return;
      }

      final pathLocal = await _descargarYGuardarLocal(resultado);
      final embedding = await _servicio.calcularEmbedding(pathLocal);
      if (!mounted) return;
      if (embedding == null) {
        _registrarIntentoKigoFallido(AppLocalizations.t(context, 'kigo_verify_rostro_no_claro'));
        return;
      }
      widget.onCapturado(pathLocal, embedding);
    } catch (_) {
      if (mounted) _registrarIntentoKigoFallido(AppLocalizations.t(context, 'kigo_verify_fallo'));
    } finally {
      if (mounted) {
        setState(() => _verificandoConKigo = false);
        if (!_capturaFinalizada) _iniciarAutoDeteccion();
      }
    }
  }

  void _registrarIntentoKigoFallido(String mensaje) {
    if (!mounted) return;
    setState(() {
      _intentosKigoFallidos++;
      _error = _kigoDisponible
          ? mensaje
          : AppLocalizations.t(context, 'kigo_verify_fallo_definitivo');
    });
  }

  /// Poll cada 3s hasta COMPLETED/FAILED, con limite duro de 3 minutos —
  /// cubre el caso ya confirmado de enrollments atorados indefinidamente en
  /// LIVENESS_STARTED (ver spec, seccion 6).
  Future<String?> _esperarResultado(String enrollmentId) async {
    const limite = Duration(minutes: 3);
    const intervalo = Duration(seconds: 3);
    final vencePara = DateTime.now().add(limite);

    while (DateTime.now().isBefore(vencePara)) {
      if (!mounted) return null;
      final estado = await _kigoVerify.consultarEstado(enrollmentId);
      if (estado.status == 'COMPLETED' && estado.fotoUrl != null) {
        return estado.fotoUrl;
      }
      if (estado.status == 'FAILED') {
        return null;
      }
      await Future.delayed(intervalo);
    }
    return null;
  }

  Future<String> _descargarYGuardarLocal(String fotoUrl) async {
    final respuesta = await http.get(Uri.parse(fotoUrl));
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/kigo-verify-${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(path).writeAsBytes(respuesta.bodyBytes);
    return path;
  }

  @override
  void dispose() {
    _timerAutoScan?.cancel();
    _detector.dispose();
    _controller?.dispose();
    _servicio.dispose();
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

    final ancho = MediaQuery.of(context).size.width * 0.72;
    final alto = ancho * 1.25;
    final colorGuia = _rostroDetectado ? AppTheme.success : AppTheme.primaryOrange;

    return Stack(
      children: [
        Positioned.fill(child: CameraPreview(_controller!)),
        Positioned.fill(
          child: MarcoGuiaCamara(
            ancho: ancho,
            alto: alto,
            colorBorde: colorGuia,
            mostrarBarrido: !_rostroDetectado,
          ),
        ),
        Positioned(
          top: 24,
          left: 16,
          right: 16,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _rostroDetectado
                    ? AppTheme.success.withValues(alpha: 0.92)
                    : Colors.black.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _rostroDetectado ? AppTheme.success : Colors.white24,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_rostroDetectado) ...[
                    const Icon(Icons.check_circle, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        AppLocalizations.t(context, 'rostro_detectado_capturando'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryOrange),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        AppLocalizations.t(context, 'encuadra_rostro_detectando'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: FloatingActionButton(
                  backgroundColor: _rostroDetectado ? AppTheme.success : AppTheme.primaryOrange,
                  onPressed: (_procesando || _verificandoConKigo || _capturaFinalizada) ? null : _capturar,
                  child: _procesando
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                        )
                      : Icon(_rostroDetectado ? Icons.check : Icons.camera_alt, color: Colors.white),
                ),
              ),
              if (_kigoDisponible) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: (_procesando || _verificandoConKigo || _capturaFinalizada) ? null : _verificarConKigo,
                  child: _verificandoConKigo
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(AppLocalizations.t(context, 'verificar_con_kigo_btn'), style: const TextStyle(color: Colors.white)),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
