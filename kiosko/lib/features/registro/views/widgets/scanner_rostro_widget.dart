import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:kigo_kiosco/core/services/camara_kiosko.dart';
import 'package:kigo_kiosco/core/services/consentimiento_servicio.dart';
import 'package:kigo_kiosco/core/services/led_servicio.dart';
import 'package:kigo_kiosco/core/theme/kigo_design.dart';
import 'package:kigo_kiosco/core/widgets/marco_guia_camara.dart';
import 'package:kigo_kiosco/core/widgets/vista_previa_camara.dart';
import 'package:kigo_kiosco/features/registro/services/face_detector_servicio.dart';
import 'consent_dialog.dart';
import 'package:kigo_kiosco/l10n/app_localizations.dart';

class EscaneoRostro extends StatefulWidget {
  const EscaneoRostro({super.key});

  @override
  State<EscaneoRostro> createState() => _EscaneoRostroState();
}

class _EscaneoRostroState extends State<EscaneoRostro> {
  CameraController? _controller;
  bool _isInitialized = false;

  final LedServicio _led = LedServicio();
  final FaceDetectorServicio _detector = FaceDetectorServicio();
  Timer? _timerAutoScan;
  bool _escaneando = false;
  bool _rostroDetectado = false;
  bool _capturaFinalizada = false;

  /// Cuántas detecciones válidas consecutivas se exigen antes de confirmar
  /// la captura. Con 1 sola, el primer frame que casualmente cruza el
  /// umbral (persona todavía acomodándose, moviéndose hacia el óvalo) ya
  /// disparaba la foto -- de ahí el reporte de "detecta muy rápido, antes
  /// de que la persona se acomode". Exigir 2 seguidas da margen a que la
  /// persona termine de posicionarse; el intervalo real entre intentos no
  /// es el timer de 700ms (`_escaneando` lo bloquea) sino lo que tarda
  /// takePicture + ML Kit modo accurate + decodeImage del JPEG en el
  /// hardware del F10 -- probablemente más de 1-2s por intento.
  static const _deteccionesRequeridas = 2;
  int _deteccionesConsecutivas = 0;

  @override
  void initState() {
    super.initState();
    // Pide consentimiento antes de activar la cámara; solo la inicializa si acepta
    WidgetsBinding.instance.addPostFrameCallback((_) => _solicitarConsentimiento());
  }

  Future<void> _solicitarConsentimiento() async {
    // Ya se pidió una vez para esta visita, en la pantalla de entrada
    // (el 100% de los visitantes pasa por ahí antes de llegar aquí).
    if (ConsentimientoServicio.otorgado) {
      _initCamera();
      return;
    }

    final bool aceptado = await mostrarConsentimientoCamara(context);

    if (!mounted) return;

    if (aceptado) {
      ConsentimientoServicio.otorgar();
      _initCamera();
    } else {
      Navigator.pop(context); // El usuario presionó "Regresar"
    }
  }

  // Inicializa la cámara de rostro con los ajustes propios del hardware.
  // En el kiosko la lente correcta y la resolución vienen de AjustesCamara:
  // pedir `high` a un sensor de 2MP hace que la vista previa se congele.
  Future<void> _initCamera() async {
    try {
      final camara = await CamaraKiosko.paraRostro();
      final controller = CamaraKiosko.controlador(
        camara,
        AjustesCamara.resolucionRostro,
      );

      await CamaraKiosko.inicializar(controller);

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _isInitialized = true;
      });

      _led.encenderIluminacion();
      _iniciarAutoDeteccion();
    } catch (e) {
      debugPrint("Error al inicializar la cámara: $e");
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
          // Válida pero todavía no estable: se descarta esta foto y se
          // sigue intentando -- la que finalmente se usa es la de la
          // detección que confirma la racha, no la primera.
          try { File(foto.path).deleteSync(); } catch (_) {}
          return;
        }

        _timerAutoScan?.cancel();
        setState(() {
          _rostroDetectado = true;
          _capturaFinalizada = true;
        });

        // Breve pausa para que el usuario reciba la retroalimentación visual
        await Future.delayed(const Duration(milliseconds: 600));

        if (mounted) {
          Navigator.pop(context, foto.path);
        }
        return;
      } else {
        _deteccionesConsecutivas = 0;
        // Descartar archivo temporal no válido
        try { File(foto.path).deleteSync(); } catch (_) {}
      }
    } catch (e) {
      debugPrint("Error en auto detección de rostro: $e");
    } finally {
      _escaneando = false;
    }
  }

  // Función para tomar la foto manualmente si el usuario lo prefiere
  Future<void> _tomarFotoYProcesar() async {
    if (_capturaFinalizada) return;
    if (_controller == null || !_controller!.value.isInitialized) return;

    _timerAutoScan?.cancel();
    _capturaFinalizada = true;

    try {
      final XFile foto = await _controller!.takePicture();
      if (mounted) {
        Navigator.pop(context, foto.path);
      }
    } catch (e) {
      debugPrint("Error al capturar la foto manualmente: $e");
      _capturaFinalizada = false;
      _iniciarAutoDeteccion();
    }
  }

  @override
  void dispose() {
    _timerAutoScan?.cancel();
    _detector.dispose();
    _controller?.dispose();
    _led.apagar();
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

    final size = MediaQuery.of(context).size;
    final ovalW = size.width * 0.72;
    final ovalH = ovalW * 1.25;
    final colorGuia = _rostroDetectado ? const Color(0xFF2DCFA8) : KigoDesign.brand;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.kBg,
        title: Text(AppLocalizations.t(context, 'apunta_a_tu_rostro'), style: TextStyle(color: context.kTextPrimary)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.kTextPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: VistaPreviaCamara(_controller!),
          ),

          // Overlay opaco con recorte oval + guía
          Positioned.fill(
            child: MarcoGuiaCamara(
              ancho: ovalW,
              alto: ovalH,
              colorBorde: colorGuia,
              mostrarBarrido: !_rostroDetectado,
            ),
          ),

          // Banner de Feedback de detección en tiempo real
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
                    Flexible(
                      child: Text(
                        AppLocalizations.t(context, 'rostro_detectado_capturando'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: KigoDesign.brand,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        AppLocalizations.t(context, 'detectando_rostro_auto'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Botón de captura manual (alternativo)
          Positioned(
            bottom: 36,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                backgroundColor: _rostroDetectado ? const Color(0xFF2DCFA8) : KigoDesign.brand,
                onPressed: _capturaFinalizada ? null : _tomarFotoYProcesar,
                child: _rostroDetectado
                    ? const Icon(Icons.check, color: Colors.white, size: 28)
                    : const Icon(Icons.camera_alt, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

