import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:kigo_salida/core/services/camara_kiosko.dart';
import 'package:kigo_salida/core/services/face_detector_servicio.dart';
import 'package:kigo_salida/core/theme/kigo_design.dart';
import 'package:kigo_salida/core/widgets/consent_dialog.dart';
import 'package:kigo_salida/core/widgets/marco_guia_camara.dart';
import 'package:kigo_salida/core/widgets/vista_previa_camara.dart';
import 'package:kigo_salida/features/salida/services/salida_servicio.dart';

/// Captura de rostro para registrar una salida -- mismo tratamiento visual
/// y misma lógica de auto-captura que
/// kiosko/lib/features/registro/views/widgets/scanner_rostro_widget.dart,
/// adaptado para mandar la foto como bitácora de SALIDA en vez de devolver
/// la ruta a un flujo de registro.
class CapturaSalidaView extends StatefulWidget {
  const CapturaSalidaView({super.key});

  @override
  State<CapturaSalidaView> createState() => _CapturaSalidaViewState();
}

enum _EstadoEnvio { capturando, enviando, exito, error }

class _CapturaSalidaViewState extends State<CapturaSalidaView> {
  CameraController? _controller;
  bool _isInitialized = false;

  final FaceDetectorServicio _detector = FaceDetectorServicio();
  Timer? _timerAutoScan;
  bool _escaneando = false;
  bool _rostroDetectado = false;
  bool _capturaFinalizada = false;
  _EstadoEnvio _estadoEnvio = _EstadoEnvio.capturando;

  static const _deteccionesRequeridas = 2;
  int _deteccionesConsecutivas = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _solicitarConsentimiento());
  }

  Future<void> _solicitarConsentimiento() async {
    final aceptado = await mostrarConsentimientoCamara(context);
    if (!mounted) return;
    if (aceptado) {
      _initCamera();
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _initCamera() async {
    try {
      final camara = await CamaraKiosko.paraRostro();
      final controller = CamaraKiosko.controlador(camara, AjustesCamara.resolucionRostro);
      await CamaraKiosko.inicializar(controller);

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _isInitialized = true;
      });

      _iniciarAutoDeteccion();
    } catch (e) {
      debugPrint('Error al inicializar la cámara: $e');
    }
  }

  void _iniciarAutoDeteccion() {
    _timerAutoScan?.cancel();
    _timerAutoScan = Timer.periodic(const Duration(milliseconds: 700), (_) {
      _intentarAutoCaptura();
    });
  }

  Future<void> _intentarAutoCaptura() async {
    if (_escaneando || _capturaFinalizada) return;
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || controller.value.isTakingPicture) {
      return;
    }

    _escaneando = true;
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

        _timerAutoScan?.cancel();
        setState(() {
          _rostroDetectado = true;
          _capturaFinalizada = true;
        });

        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) _enviarSalida(foto.path);
        return;
      } else {
        _deteccionesConsecutivas = 0;
        try { File(foto.path).deleteSync(); } catch (_) {}
      }
    } catch (e) {
      debugPrint('Error en auto detección de rostro: $e');
    } finally {
      _escaneando = false;
    }
  }

  Future<void> _enviarSalida(String pathFoto) async {
    setState(() => _estadoEnvio = _EstadoEnvio.enviando);
    try {
      await SalidaServicio().reportarSalida(pathFoto);
      if (!mounted) return;
      setState(() => _estadoEnvio = _EstadoEnvio.exito);
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Error al reportar salida: $e');
      if (!mounted) return;
      setState(() => _estadoEnvio = _EstadoEnvio.error);
    }
  }

  void _reintentar() {
    setState(() {
      _estadoEnvio = _EstadoEnvio.capturando;
      _capturaFinalizada = false;
      _rostroDetectado = false;
      _deteccionesConsecutivas = 0;
    });
    _iniciarAutoDeteccion();
  }

  @override
  void dispose() {
    _timerAutoScan?.cancel();
    _detector.dispose();
    _controller?.dispose();
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

    if (_estadoEnvio == _EstadoEnvio.enviando || _estadoEnvio == _EstadoEnvio.exito || _estadoEnvio == _EstadoEnvio.error) {
      return _buildEstadoEnvio();
    }

    final size = MediaQuery.of(context).size;
    final ovalW = size.width * 0.72;
    final ovalH = ovalW * 1.25;
    final colorGuia = _rostroDetectado ? const Color(0xFF2DCFA8) : KigoDesign.brand;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.kBg,
        title: Text('Apunta tu rostro a la cámara', style: TextStyle(color: context.kTextPrimary)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.kTextPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: VistaPreviaCamara(_controller!)),
          Positioned.fill(
            child: MarcoGuiaCamara(
              ancho: ovalW,
              alto: ovalH,
              colorBorde: colorGuia,
              mostrarBarrido: !_rostroDetectado,
            ),
          ),
          Positioned(
            top: 18,
            left: 20,
            right: 20,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _rostroDetectado
                    ? const Color(0xFF2DCFA8).withValues(alpha: 0.92)
                    : Colors.black.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _rostroDetectado ? const Color(0xFF2DCFA8) : Colors.white24,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_rostroDetectado) ...[
                    const Icon(Icons.check_circle, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    const Flexible(
                      child: Text(
                        'Rostro detectado, registrando salida…',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(strokeWidth: 2, color: KigoDesign.brand),
                    ),
                    const SizedBox(width: 10),
                    const Flexible(
                      child: Text(
                        'Buscando tu rostro…',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoEnvio() {
    late final Widget icono;
    late final String titulo;
    late final String subtitulo;
    late final Color color;

    switch (_estadoEnvio) {
      case _EstadoEnvio.enviando:
        icono = const CircularProgressIndicator(color: KigoDesign.brand, strokeWidth: 2.5);
        titulo = 'Registrando tu salida…';
        subtitulo = '';
        color = KigoDesign.brand;
      case _EstadoEnvio.exito:
        icono = const Icon(Icons.check_circle, color: Color(0xFF2DCFA8), size: 72);
        titulo = '¡Salida registrada!';
        subtitulo = 'Gracias, que tengas buen viaje.';
        color = const Color(0xFF2DCFA8);
      case _EstadoEnvio.error:
        icono = Icon(Icons.error_outline, color: KigoDesign.error, size: 72);
        titulo = 'No se pudo registrar tu salida';
        subtitulo = 'Revisa la conexión e inténtalo de nuevo.';
        color = KigoDesign.error;
      case _EstadoEnvio.capturando:
        icono = const SizedBox.shrink();
        titulo = '';
        subtitulo = '';
        color = KigoDesign.brand;
    }

    return Scaffold(
      backgroundColor: context.kBg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              icono,
              const SizedBox(height: 24),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.kTextPrimary, fontFamily: 'Unbounded', fontSize: 22, fontWeight: FontWeight.w700),
              ),
              if (subtitulo.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(subtitulo, textAlign: TextAlign.center, style: TextStyle(color: context.kTextSecondary, fontSize: 15)),
              ],
              if (_estadoEnvio == _EstadoEnvio.error) ...[
                const SizedBox(height: 28),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: color, minimumSize: const Size(200, 56)),
                  onPressed: _reintentar,
                  child: const Text('Reintentar'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
