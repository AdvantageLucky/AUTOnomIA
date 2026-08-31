import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../../../services/kigo_verify_servicio.dart';
import '../../../../services/reconocimiento_facial_servicio.dart';
import '../../../../theme/app_theme.dart';
import 'kigo_verify_webview_view.dart';

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
  final _kigoVerify = KigoVerifyServicio();
  bool _procesando = false;
  bool _verificandoConKigo = false;
  String? _error;

  /// Tras 5 intentos fallidos de Kigo Verify en este paso, se oculta la
  /// opción y se fuerza el camino manual con la cámara propia.
  static const _maxIntentosKigo = 5;
  int _intentosKigoFallidos = 0;
  bool get _kigoDisponible => _intentosKigoFallidos < _maxIntentosKigo;

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
      await _controller!.setFlashMode(FlashMode.off);
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

  Future<void> _verificarConKigo() async {
    if (_procesando || _verificandoConKigo) return;
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
      if (resultado == null) {
        _registrarIntentoKigoFallido('No se pudo completar la verificación con Kigo, intenta de nuevo o usa la cámara');
        return;
      }

      final pathLocal = await _descargarYGuardarLocal(resultado);
      final embedding = await _servicio.calcularEmbedding(pathLocal);
      if (embedding == null) {
        _registrarIntentoKigoFallido('No detectamos tu rostro con claridad en la foto de Kigo, intenta de nuevo o usa la cámara');
        return;
      }
      widget.onCapturado(pathLocal, embedding);
    } catch (_) {
      if (mounted) _registrarIntentoKigoFallido('No se pudo completar la verificación con Kigo, intenta de nuevo o usa la cámara');
    } finally {
      if (mounted) setState(() => _verificandoConKigo = false);
    }
  }

  void _registrarIntentoKigoFallido(String mensaje) {
    if (!mounted) return;
    setState(() {
      _intentosKigoFallidos++;
      _error = _kigoDisponible
          ? mensaje
          : 'No se pudo verificar con Kigo tras varios intentos. Usa la cámara para continuar.';
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
          child: Builder(
            builder: (context) {
              final ancho = MediaQuery.of(context).size.width * 0.6;
              final alto = ancho * 1.35; // óvalo de cara, no círculo
              // Un Border.all() sobre BorderRadius elíptico al 50% deja
              // costuras visibles donde se encuentran los arcos de las 4
              // esquinas — se dibuja el óvalo real con CustomPaint en vez
              // de simularlo con border-radius.
              return SizedBox(
                width: ancho,
                height: alto,
                child: CustomPaint(painter: _OvaloGuiaPainter()),
              );
            },
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: FloatingActionButton(
                  backgroundColor: AppTheme.primaryOrange,
                  onPressed: (_procesando || _verificandoConKigo) ? null : _capturar,
                  child: _procesando
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                        )
                      : const Icon(Icons.camera_alt, color: Colors.white),
                ),
              ),
              if (_kigoDisponible) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: (_procesando || _verificandoConKigo) ? null : _verificarConKigo,
                  child: _verificandoConKigo
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Verificar con Kigo', style: TextStyle(color: Colors.white)),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _OvaloGuiaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryOrange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final rect = Offset.zero & size;
    canvas.drawOval(rect.deflate(1.5), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
