/* VISTA PRINCIPAL DEL REGISTRO VEHICULAR */

import 'package:flutter/material.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:kigo_kiosco/core/services/evidencia_calidad_servicio.dart';
import 'package:kigo_kiosco/core/theme/kigo_design.dart';
import 'package:kigo_kiosco/core/widgets/presionable.dart';
import 'package:kigo_kiosco/features/registro/services/text_to_speak_servicio.dart';
import 'package:kigo_kiosco/features/registro/views/casa_destino_view.dart';
import 'package:kigo_kiosco/features/registro/views/resumen_solicitud_view.dart';
import 'package:kigo_kiosco/features/registro/views/widgets/face_approach_animation.dart';
import 'package:kigo_kiosco/features/registro/views/widgets/ine_approach_animation.dart';
import 'package:kigo_kiosco/features/registro/views/widgets/scanner_ine_widget.dart';
import 'package:kigo_kiosco/features/registro/views/widgets/scanner_rostro_widget.dart';
import 'package:kigo_kiosco/features/registro/views/widgets/step_indicator.dart';
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
  final TextToSpeakServicio _textToSpeakServicio = TextToSpeakServicio();
  bool _isSpeaking = false;

  VehicularRegisterViewModel get viewModel => widget.viewModel;

  @override
  void initState() {
    super.initState();
    viewModel.addListener(_refresh);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Config sin capturas obligatorias: no hay nada que escanear, se pasa
      // directo a elegir la casa destino.
      if (viewModel.pasos.isEmpty) {
        _continuarACasaDestino();
        return;
      }
      _speakText(AppLocalizations.t(context, 'welcome_vehicular_message'));
    });
  }

  @override
  void dispose() {
    viewModel.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  Future<void> _speakText(String text) async {
    if (_isSpeaking) return;
    setState(() => _isSpeaking = true);

    try {
      await _textToSpeakServicio.speak(text);
    } catch (_) {
      // Ignorar errores de TTS para no bloquear la UI.
    } finally {
      if (mounted) setState(() => _isSpeaking = false);
    }
  }

  // ── Flujo ───────────────────────────────────────────────────────────────────

  Future<void> _continuarProceso() async {
    if (viewModel.isProcessing || viewModel.pasos.isEmpty) return;

    switch (viewModel.pasoActual) {
      case PasoVehicular.ine:
        await _capturarIne();
      case PasoVehicular.rostro:
        await _capturarRostro();
    }
  }

  /// Avanza al siguiente paso de captura o, si ya fue el último, cierra el flujo.
  Future<void> _avanzar() async {
    if (!viewModel.isLastStep) {
      viewModel.nextStep();
      return;
    }
    await _continuarACasaDestino();
  }

  Future<void> _continuarACasaDestino() async {
    if (!mounted) return;

    // La lectura de placa arrancó en paralelo desde que se creó el
    // viewmodel — para cuando se llega aquí, normalmente ya está resuelta.
    // Sin lectura y si este visitante la necesita, el teclado manual es el
    // único respaldo (no hay cámara dedicada a la placa todavía).
    final placa = await viewModel.leerPlaca();
    if (!mounted) return;
    if (placa == null && viewModel.requierePlaca) {
      final placaManual = await pedirConfirmacionPlaca(context);
      if (!mounted) return;
      if (placaManual == null) {
        // El conductor canceló: no hay un punto intermedio al que reanudar.
        Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      }
      viewModel.confirmarPlaca(placaManual);
    }

    if (!mounted) return;

    // El invitado ya trae casa destino en su invitación.
    if (!viewModel.registrationData.esInvitado) {
      final String? casa = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) => CasaDestinoView(totalSteps: viewModel.indicatorTotalSteps),
        ),
      );

      // Si el visitante da "atrás" aquí, se cancela toda la solicitud: no hay un
      // punto intermedio al que reanudar.
      if (casa == null) {
        if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      }

      viewModel.registrationData.casaDestino = casa;
    }

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

      _speakText(AppLocalizations.t(context, 'voice_instruction_ine'));
      final String? pathFoto = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (_) => const EscaneoInePage()),
      );

      if (pathFoto == null) return; // el visitante canceló

      final resultado = await viewModel.procesarEscaneoIne(pathFoto);
      if (resultado == CalidadCaptura.ok) {
        _speakText(AppLocalizations.t(context, 'ine_detected_title'));
        await _avanzar();
        return;
      }

      final esBorrosa = resultado == CalidadCaptura.borrosa;
      _speakText(AppLocalizations.t(context, esBorrosa ? 'ine_borrosa_message' : 'ine_invalid_message'));
      if (!mounted) return;
      await _mostrarError(
        icono: Icons.error_outline_rounded,
        titulo: AppLocalizations.t(context, esBorrosa ? 'ine_borrosa_error_title' : 'ine_invalid_error_title'),
        mensaje: AppLocalizations.t(context, esBorrosa ? 'ine_borrosa_error_content' : 'ine_invalid_error_content'),
      );
    }
  }

  Future<void> _capturarRostro() async {
    while (true) {
      if (!mounted) return;

      _speakText(AppLocalizations.t(context, 'voice_instruction_face'));
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
      _speakText(AppLocalizations.t(context, esBorrosa ? 'face_borrosa_message' : 'face_not_detected_message'));
      if (!mounted) return;
      await _mostrarError(
        icono: Icons.face_retouching_off,
        titulo: AppLocalizations.t(context, esBorrosa ? 'face_borrosa_error_title' : 'face_not_detected_error_title'),
        mensaje: AppLocalizations.t(context, esBorrosa ? 'face_borrosa_error_content' : 'face_not_detected_error_content'),
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
              child: Text(titulo, style: TextStyle(color: context.kTextPrimary)),
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

    return Scaffold(
      backgroundColor: context.kBg,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _buildVoiceWaveButton(),
      body: SizedBox.expand(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.only(left: 42, right: 42, top: 32, bottom: 40),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            _buildHeader(),
                            Positioned(left: 0, child: _buildTopBackButton()),
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
                          ? const Center(
                              child: CircularProgressIndicator(color: KigoDesign.brand))
                          : _buildMainButton(AppLocalizations.t(context, viewModel.currentStepData.buttonTextKey)),
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
              style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 18),
        Text(
          AppLocalizations.t(context, 'kigo_label'),
          style: TextStyle(color: context.kTextPrimary, fontSize: 34, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  Widget _buildGuiaVisual() {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: context.kSurface1,
          borderRadius: BorderRadius.circular(24),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(24)),
          child: switch (viewModel.pasoActual) {
            PasoVehicular.ine => const IneApproachAnimation(),
            PasoVehicular.rostro => const FaceApproachAnimation(),
          },
        ),
      ),
    );
  }

  Widget _buildMainButton(String text) {
    return Presionable(
      onTap: _continuarProceso,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: 260,
        height: 260,
        decoration: const BoxDecoration(color: KigoDesign.brand, shape: BoxShape.circle),
        child: ClipOval(
          child: Stack(
            children: [
              Positioned(
                right: -18,
                top: -40,
                child: Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    color: KigoDesign.brandHover.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        text,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        AppLocalizations.t(context, 'continue_press_text'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFFFE3DC),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceWaveButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0, right: 20.0),
      child: FloatingActionButton(
        onPressed: _isSpeaking ? null : () => _speakText(AppLocalizations.t(context, 'listening_message')),
        backgroundColor: KigoDesign.brand,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: _isSpeaking
              ? const LoadingIndicator(
                  indicatorType: Indicator.audioEqualizer,
                  colors: [Colors.white],
                  strokeWidth: 2.6,
                  backgroundColor: Colors.transparent,
                  pathBackgroundColor: Colors.transparent,
                )
              : const Icon(Icons.mic, color: Colors.white, size: 32),
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
            const Icon(Icons.arrow_back_rounded, color: KigoDesign.brand, size: 24),
            const SizedBox(width: 10),
            Text(
              AppLocalizations.t(context, 'back_button_text'),
              style: TextStyle(color: context.kTextPrimary, fontSize: 18, fontWeight: FontWeight.w700),
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
