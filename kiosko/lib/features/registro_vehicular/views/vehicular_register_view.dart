import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:kigo_kiosco/core/services/asistente_controller.dart';
import 'package:kigo_kiosco/core/services/evidencia_calidad_servicio.dart';
import 'package:kigo_kiosco/core/theme/kigo_design.dart';
import 'package:kigo_kiosco/core/widgets/boton_asistente_flotante.dart';
import 'package:kigo_kiosco/core/widgets/etiqueta_asistente.dart';
import 'package:kigo_kiosco/core/widgets/presionable.dart';
import 'package:kigo_kiosco/features/registro/views/casa_destino_view.dart';
import 'package:kigo_kiosco/features/registro/views/resumen_solicitud_view.dart';
import 'package:kigo_kiosco/features/registro/views/widgets/face_approach_animation.dart';
import 'package:kigo_kiosco/features/registro/views/widgets/ine_approach_animation.dart';
import 'package:kigo_kiosco/features/registro/views/widgets/scanner_ine_widget.dart';
import 'package:kigo_kiosco/features/registro/views/widgets/scanner_rostro_widget.dart';
import 'package:kigo_kiosco/features/registro/views/widgets/step_indicator.dart';
import 'package:kigo_kiosco/features/registro/models/paso_registro.dart';
import 'package:kigo_kiosco/features/registro_vehicular/viewmodels/vehicular_register_viewmodel.dart';
import 'package:kigo_kiosco/features/registro_vehicular/views/confirmar_placa_view.dart';
import 'package:kigo_kiosco/l10n/app_localizations.dart';

/// Gemela de `TouchRegisterView` para la caseta vehicular. Comparte los
/// servicios de OCR y detección facial, y agrega la captura de placa. Vive
/// aparte porque los dos flujos evolucionan por separado: el vehicular atiende
/// a alguien dentro de un coche, con la fila detrás esperando.
class VehicularRegisterView extends StatefulWidget {
  final VehicularRegisterViewModel viewModel;

  const VehicularRegisterView({super.key, required this.viewModel});

  @override
  State<VehicularRegisterView> createState() => _VehicularRegisterViewState();
}

class _VehicularRegisterViewState extends State<VehicularRegisterView> {
  final AsistenteController _asistenteController = AsistenteController();

  VehicularRegisterViewModel get viewModel => widget.viewModel;

  @override
  void initState() {
    super.initState();
    viewModel.addListener(_refresh);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Sin ningún paso configurado no hay nada que pedir: es el invitado
      // cuyo QR basta por sí solo, así que se va directo al resumen.
      if (viewModel.pasos.isEmpty) {
        _irAResumen();
        return;
      }
      _narrar(AppLocalizations.t(context, 'welcome_vehicular_message'));
      // El dashboard puede poner PLACA o DESTINO de primero: en ese caso no
      // hay nada que capturar todavía y la pantalla arranca resolviéndolo.
      _ejecutarSiEsAutomatico();
    });
  }

  @override
  void dispose() {
    viewModel.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  // La presentación verbal única de la mascota ("Hola, soy tu
  // asistente...") vive en QrScannerView, la entrada real del kiosko —
  // para cuando el visitante llega aquí ya la vio.
  void _narrar(String texto) => _asistenteController.decir(texto);

  // ── Flujo ───────────────────────────────────────────────────────────────────

  Future<void> _continuarProceso() async {
    if (viewModel.isProcessing || viewModel.pasos.isEmpty) return;

    switch (viewModel.pasoActual) {
      case PasoRegistro.ine:
        await _capturarIne();
      case PasoRegistro.rostro:
        await _capturarRostro();
      // Los automaticos no llegan por el boton: los dispara
      // _ejecutarSiEsAutomatico al tocarles el turno.
      case PasoRegistro.placa:
      case PasoRegistro.destino:
        await _ejecutarSiEsAutomatico();
    }
  }

  /// Cierra el paso actual: si era el último va al resumen, si no avanza y
  /// deja corriendo el siguiente por si se resuelve solo.
  Future<void> _avanzar() async {
    if (viewModel.isLastStep) {
      _irAResumen();
      return;
    }
    viewModel.nextStep();
    await _ejecutarSiEsAutomatico();
  }

  /// PLACA y DESTINO no esperan un toque: se resuelven al llegarles el turno.
  /// La recursión vía [_avanzar] termina siempre, porque cada vuelta consume
  /// un paso de una lista finita.
  Future<void> _ejecutarSiEsAutomatico() async {
    if (!mounted || viewModel.pasos.isEmpty) return;
    if (!esPasoAutomatico(viewModel.pasoActual)) return;

    switch (viewModel.pasoActual) {
      case PasoRegistro.placa:
        await _pasoPlaca();
      case PasoRegistro.destino:
        await _pasoCasaDestino();
      case PasoRegistro.ine:
      case PasoRegistro.rostro:
        break;
    }
  }

  Future<void> _pasoPlaca() async {
    // La lectura arrancó en paralelo desde que se creó el viewmodel — para
    // cuando se llega aquí, normalmente ya está resuelta. Sin lectura, el
    // teclado manual es el único respaldo (no hay cámara dedicada a la placa
    // todavía).
    final placa = await viewModel.leerPlaca();
    if (!mounted) return;
    if (placa == null) {
      final placaManual = await pedirConfirmacionPlaca(context);
      if (!mounted) return;
      if (placaManual == null) {
        // El conductor canceló: no hay un punto intermedio al que reanudar.
        Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      }
      viewModel.confirmarPlaca(placaManual);
    }
    await _avanzar();
  }

  Future<void> _pasoCasaDestino() async {
    if (!mounted) return;
    final String? casa = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => CasaDestinoView(
          currentStep: viewModel.indicatorStep,
          totalSteps: viewModel.indicatorTotalSteps,
        ),
      ),
    );

    // Si el visitante da "atrás" aquí, se cancela toda la solicitud: no hay un
    // punto intermedio al que reanudar.
    if (casa == null) {
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    viewModel.registrationData.casaDestino = casa;
    await _avanzar();
  }

  void _irAResumen() {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResumenSolicitudView(
          registrationData: viewModel.registrationData,
          totalSteps: viewModel.indicatorTotalSteps,
        ),
      ),
    );
  }

  Future<void> _capturarIne() async {
    while (true) {
      if (!mounted) return;

      _narrar(AppLocalizations.t(context, 'voice_instruction_ine'));
      final String? pathFoto = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (_) => const EscaneoInePage()),
      );

      if (pathFoto == null) return; // el visitante canceló

      final resultado = await viewModel.procesarEscaneoIne(pathFoto);
      if (resultado == CalidadCaptura.ok) {
        _narrar(AppLocalizations.t(context, 'ine_detected_title'));
        await _avanzar();
        return;
      }

      final esBorrosa = resultado == CalidadCaptura.borrosa;
      _narrar(
        AppLocalizations.t(
          context,
          esBorrosa ? 'ine_borrosa_message' : 'ine_invalid_message',
        ),
      );
      if (!mounted) return;
      await _mostrarError(
        icono: Icons.error_outline_rounded,
        titulo: AppLocalizations.t(
          context,
          esBorrosa ? 'ine_borrosa_error_title' : 'ine_invalid_error_title',
        ),
        mensaje: AppLocalizations.t(
          context,
          esBorrosa ? 'ine_borrosa_error_content' : 'ine_invalid_error_content',
        ),
      );
    }
  }

  Future<void> _capturarRostro() async {
    while (true) {
      if (!mounted) return;

      _narrar(AppLocalizations.t(context, 'voice_instruction_face'));
      final String? pathFoto = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (_) => const EscaneoRostro()),
      );

      if (pathFoto == null) return;

      final resultado = await viewModel.procesarEscaneoRostro(pathFoto);
      if (resultado == CalidadCaptura.ok) {
        await _avanzar();
        return;
      }

      final esBorrosa = resultado == CalidadCaptura.borrosa;
      _narrar(
        AppLocalizations.t(
          context,
          esBorrosa ? 'face_borrosa_message' : 'face_not_detected_message',
        ),
      );
      if (!mounted) return;
      await _mostrarError(
        icono: Icons.face_retouching_off,
        titulo: AppLocalizations.t(
          context,
          esBorrosa
              ? 'face_borrosa_error_title'
              : 'face_not_detected_error_title',
        ),
        mensaje: AppLocalizations.t(
          context,
          esBorrosa
              ? 'face_borrosa_error_content'
              : 'face_not_detected_error_content',
        ),
      );
    }
  }

  Future<void> _mostrarError({
    required IconData icono,
    required String titulo,
    required String mensaje,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: context.kSurfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KigoDesign.radiusLg),
        ),
        title: Row(
          children: [
            Icon(icono, color: KigoDesign.brand, size: 28),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                titulo,
                style: TextStyle(color: context.kTextPrimary),
              ),
            ),
          ],
        ),
        content: Text(
          mensaje,
          style: TextStyle(color: context.kTextSecondary, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.t(context, 'retry_button_text'),
              style: const TextStyle(
                color: KigoDesign.brand,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── UI ──────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (viewModel.pasos.isEmpty) {
      return Scaffold(
        backgroundColor: context.kBg,
        body: Center(child: CircularProgressIndicator(color: KigoDesign.brand)),
      );
    }

    return Stack(
      children: [
        Scaffold(
          backgroundColor: context.kBg,
          body: SizedBox.expand(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 42,
                        right: 42,
                        top: 32,
                        bottom: 40,
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                _buildHeader(),
                                Positioned(
                                  left: 0,
                                  child: _buildTopBackButton(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          StepIndicator(
                            currentStep: viewModel.indicatorStep,
                            totalSteps: viewModel.indicatorTotalSteps,
                          ),
                          const SizedBox(height: 24),
                          _buildGuiaVisual(),
                          const SizedBox(height: 32),
                          viewModel.isProcessing
                              ? _buildBotonCargando()
                              : _buildMainButton(
                                  AppLocalizations.t(
                                    context,
                                    viewModel.currentStepData.buttonTextKey,
                                  ),
                                ),
                          if (viewModel.currentStep > 0) ...[
                            const SizedBox(height: 12),
                            _buildBackButton(),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 28, top: 12),
                  child: _buildFooter(),
                ),
              ],
            ),
          ),
        ),
        BotonAsistenteFlotante(
          // Mismo padding real que TouchRegisterView (top: 32, right: 42).
          topDelBorde: 32,
          rightDelBorde: 42,
          controlador: _asistenteController,
          onRespuestaLibre:
              (_) {}, // esta pantalla no usa Q&A libre por texto, solo narra
          onCampoExtraido: (_) {}, // no llena campos -- tipoCampo queda null
        ),
        const Positioned(
          top: 32 + KigoDesign.offsetEtiquetaAsistente,
          right: 42,
          child: EtiquetaAsistente(),
        ),
      ],
    );
  }

  Widget _buildTopBackButton() {
    return Presionable(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: KigoDesign.brand,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: KigoDesign.brand,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Center(
            child: Text(
              'K',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 18),
        Text(
          AppLocalizations.t(context, 'kigo_label'),
          style: TextStyle(
            color: context.kTextPrimary,
            fontSize: 34,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildGuiaVisual() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxH = math.min(constraints.maxWidth * 0.75, 300.0);
        return SizedBox(
          width: double.infinity,
          height: maxH,
          child: Container(
            decoration: BoxDecoration(
              color: context.kSurface1,
              borderRadius: BorderRadius.circular(24),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(24)),
              child: switch (viewModel.pasoActual) {
                PasoRegistro.ine => const IneApproachAnimation(),
                PasoRegistro.rostro => const FaceApproachAnimation(),
                // No se alcanzan a ver: estos pasos empujan su pantalla.
                PasoRegistro.placa || PasoRegistro.destino => const SizedBox.shrink(),
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildBotonCargando() {
    return Container(
      width: double.infinity,
      height: 76,
      decoration: BoxDecoration(
        color: KigoDesign.brand.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
          ),
          SizedBox(width: 14),
          Text(
            'Procesando captura...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainButton(String text) {
    return Presionable(
      onTap: _continuarProceso,
      child: Container(
        width: double.infinity,
        height: 76,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: KigoDesign.brand,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: KigoDesign.brand.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_alt_rounded,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(width: 14),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppLocalizations.t(context, 'continue_press_text'),
                    style: const TextStyle(
                      color: Color(0xFFFFE3DC),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Presionable(
      onTap: viewModel.previousStep,
      child: Container(
        width: double.infinity,
        height: 62,
        decoration: BoxDecoration(
          color: context.kSurface2,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.kBorder, width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.arrow_back_rounded,
              color: KigoDesign.brand,
              size: 24,
            ),
            const SizedBox(width: 10),
            Text(
              AppLocalizations.t(context, 'back_button_text'),
              style: TextStyle(
                color: context.kTextPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Text(
      AppLocalizations.t(context, 'footer_text'),
      textAlign: TextAlign.center,
      style: TextStyle(
        color: context.kTextTertiary,
        fontSize: 14,
        letterSpacing: 2,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
