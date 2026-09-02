import 'dart:async';

import 'package:kigo_kiosco/core/theme/kigo_design.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:kigo_kiosco/core/services/camara_kiosko.dart';
import 'package:kigo_kiosco/core/services/consentimiento_servicio.dart';
import 'package:kigo_kiosco/core/services/led_servicio.dart';
import 'package:kigo_kiosco/core/widgets/vista_previa_camara.dart';
import 'package:kigo_kiosco/features/registro/views/widgets/consent_dialog.dart';
import 'package:kigo_kiosco/features/registro_vehicular/services/placa_detector_servicio.dart';
import 'package:kigo_kiosco/l10n/app_localizations.dart';

/// Lectura de placa con la cámara propia del kiosko -- revive lo que
/// ADR-0026 quitó (una pantalla de captura) porque el hardware dedicado que
/// esa decisión daba por sentado ("cámara IP aparte, invisible para el
/// conductor") no existe. Mismo motor de OCR que ya estaba construido y sin
/// usar (`PlacaDetectorServicio`), mismo patrón de auto-captura que
/// `EscaneoInePage`. Si no detecta nada, la vista que llama a esta cae al
/// teclado manual (`ConfirmarPlacaView`) -- ese respaldo no cambia.
class EscaneoPlacaView extends StatefulWidget {
  const EscaneoPlacaView({super.key});

  @override
  State<EscaneoPlacaView> createState() => _EscaneoPlacaViewState();
}

class _EscaneoPlacaViewState extends State<EscaneoPlacaView> {
  CameraController? _controller;
  bool _isInitialized = false;

  final LedServicio _led = LedServicio();
  final PlacaDetectorServicio _detector = PlacaDetectorServicio();

  /// false cuando la lente es de foco fijo (el caso normal en este hardware,
  /// calibrada para rostro a ~50-70cm, no para documentos de cerca): no hay
  /// nada que dirigir y al conductor hay que decirle que acerque/aleje la
  /// placa hasta que caiga en foco.
  bool _hayEnfoque = true;

  Timer? _autoTimer;
  bool _sondeando = false;
  bool _cerrando = false;
  bool _sinDeteccion = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _solicitarConsentimiento());
  }

  Future<void> _solicitarConsentimiento() async {
    if (ConsentimientoServicio.otorgado) {
      _initCamera();
      return;
    }
    final aceptado = await mostrarConsentimientoCamara(context);
    if (!mounted) return;
    if (aceptado) {
      ConsentimientoServicio.otorgar();
      _initCamera();
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _initCamera() async {
    try {
      final camara = await CamaraKiosko.paraDocumento();
      final controller = CamaraKiosko.controlador(camara, AjustesCamara.resolucionDocumento);
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

      _hayEnfoque = await CamaraKiosko.enfocarEn(controller, const Offset(0.5, 0.5));
      if (mounted) setState(() {});

      _iniciarAutoCaptura();
    } catch (e) {
      debugPrint('Error al inicializar la cámara para placa: $e');
    }
  }

  Future<void> _enfocarDondeTocaron(TapDownDetails detalles) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final tam = context.size;
    if (tam == null) return;
    await CamaraKiosko.enfocarEn(
      controller,
      Offset(
        (detalles.localPosition.dx / tam.width).clamp(0.0, 1.0),
        (detalles.localPosition.dy / tam.height).clamp(0.0, 1.0),
      ),
    );
  }

  void _iniciarAutoCaptura() {
    _autoTimer?.cancel();
    _autoTimer = Timer.periodic(const Duration(milliseconds: 1400), (_) => _sondeoAutomatico());
  }

  Future<void> _sondeoAutomatico() async {
    if (_sondeando || _cerrando) return;
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || controller.value.isTakingPicture) {
      return;
    }

    _sondeando = true;
    try {
      final XFile foto = await controller.takePicture();
      final resultado = await _detector.analizarPlaca(foto.path);

      if (!mounted || _cerrando) return;
      if (resultado.fueLeida) {
        _cerrando = true;
        _autoTimer?.cancel();
        Navigator.pop(context, resultado.texto);
      }
    } catch (e) {
      debugPrint('Sondeo de placa falló: $e');
    } finally {
      _sondeando = false;
    }
  }

  Future<void> _tomarFotoYProcesar() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_cerrando) return;

    try {
      _autoTimer?.cancel();
      while (_sondeando) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      if (_cerrando || !mounted) return;

      final XFile foto = await _controller!.takePicture();
      final resultado = await _detector.analizarPlaca(foto.path);
      if (!mounted) return;

      if (resultado.fueLeida) {
        _cerrando = true;
        Navigator.pop(context, resultado.texto);
      } else {
        // No se leyó nada en el intento manual -- se avisa y se reanuda el
        // sondeo en vez de dejar la pantalla congelada; el botón "usar
        // teclado" sigue siendo la salida rápida si el conductor no quiere
        // seguir intentando.
        setState(() => _sinDeteccion = true);
        _iniciarAutoCaptura();
      }
    } catch (e) {
      debugPrint('Error al capturar la placa: $e');
      _iniciarAutoCaptura();
    }
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _led.apagar();
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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.kBg,
        title: Text(
          AppLocalizations.t(context, 'apunta_a_tu_placa'),
          style: TextStyle(color: context.kTextPrimary),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.kTextPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTapDown: _hayEnfoque ? _enfocarDondeTocaron : null,
              child: VistaPreviaCamara(_controller!),
            ),
          ),
          // Recuadro guía -- una placa mexicana es más ancha que alta
          // (~2:1), a diferencia de la INE.
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.width * 0.8 * 0.45,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(color: Colors.green, strokeWidth: 2),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _hayEnfoque
                          ? AppLocalizations.t(context, 'deteccion_automatica_placa')
                          : AppLocalizations.t(context, 'acerca_aleja_placa'),
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_sinDeteccion)
            Positioned(
              top: 76,
              left: 24,
              right: 24,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: KigoDesign.brand.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    AppLocalizations.t(context, 'no_se_detecto_placa_reintentando'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Center(
                  child: FloatingActionButton(
                    backgroundColor: KigoDesign.brand,
                    onPressed: _tomarFotoYProcesar,
                    child: const Icon(Icons.camera_alt, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 14),
                TextButton(
                  onPressed: () {
                    _cerrando = true;
                    _autoTimer?.cancel();
                    Navigator.pop(context);
                  },
                  child: Text(
                    AppLocalizations.t(context, 'usar_teclado_button'),
                    style: const TextStyle(color: Colors.white, decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
