/* VISTA PRINCIPAL DE REGISTRO TÁCTIL */

import 'package:kigo_kiosco/core/theme/kigo_design.dart';
import 'package:kigo_kiosco/features/registro/views/widgets/scanner_ine_widget.dart';
import 'package:kigo_kiosco/features/registro/views/widgets/ine_approach_animation.dart';
import 'package:kigo_kiosco/features/registro/views/widgets/face_approach_animation.dart';
import 'package:flutter/material.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:kigo_kiosco/features/registro/viewmodels/touch_register_viewmodel.dart';
import 'package:kigo_kiosco/features/registro/views/casa_destino_view.dart';
import 'package:kigo_kiosco/features/registro/views/resumen_solicitud_view.dart';
import 'package:kigo_kiosco/features/registro/views/widgets/step_indicator.dart';
import 'package:kigo_kiosco/features/registro/views/widgets/scanner_rostro_widget.dart';
import 'package:kigo_kiosco/features/registro/services/text_to_speak_servicio.dart';
import 'package:kigo_kiosco/core/models/kiosko_config.dart';
import 'package:kigo_kiosco/l10n/app_localizations.dart';

class TouchRegisterView extends StatefulWidget {
  final KioskoConfig? config;
  const TouchRegisterView({super.key, this.config});

  @override
  State<TouchRegisterView> createState() => _TouchRegisterViewState();
}

class _TouchRegisterViewState extends State<TouchRegisterView> {
  late final TouchRegisterViewModel viewModel;
  final TextToSpeakServicio _textToSpeakServicio = TextToSpeakServicio();
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    viewModel = TouchRegisterViewModel(widget.config);
    viewModel.addListener(_refresh);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakText(AppLocalizations.t(context, 'welcome_message'));
    });
  }

  @override
  void dispose() {
    viewModel.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    setState(() {});
  }

  Future<void> _speakText(String text) async {
    if (_isSpeaking) return;

    setState(() {
      _isSpeaking = true;
    });

    try {
      await _textToSpeakServicio.speak(text);
    } catch (_) {
      // Ignorar errores de TTS para no bloquear la UI.
    } finally {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
        });
      }
    }
  }

  Future<void> _continueProcess() async {
    if (viewModel.isProcessingIne || viewModel.isProcessingRostro) return;

    if (viewModel.pasoActual == PasoTouch.ine) {
      bool esIneValida = false;
      while (!esIneValida) {
        if (!mounted) return;

        _speakText(AppLocalizations.t(context, 'voice_instruction_ine'));
        final String? pathFoto = await Navigator.push<String>(
          context,
          MaterialPageRoute(builder: (_) => const EscaneoInePage()),
        );

        if (pathFoto == null) break;

        final bool exito = await viewModel.procesarEscaneoIne(pathFoto);
        if (exito) {
          esIneValida = true;
          if (mounted) _speakText(AppLocalizations.t(context, 'ine_detected_title'));
          if (viewModel.isLastStep) {
            _irACasaDestino();
          } else {
            viewModel.nextStep();
          }
        } else {
          if (mounted) {
            _speakText(AppLocalizations.t(context, 'ine_invalid_message'));
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return AlertDialog(
                  backgroundColor: context.kSurfaceCard,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  title: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: KigoDesign.brand, size: 28),
                      const SizedBox(width: 12),
                      Flexible(child: Text(AppLocalizations.t(context, 'ine_invalid_error_title'), style: TextStyle(color: context.kTextPrimary))),
                    ],
                  ),
                  content: Text(
                    AppLocalizations.t(context, 'ine_invalid_error_content'),
                    style: TextStyle(color: context.kTextSecondary, fontSize: 16),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        AppLocalizations.t(context, 'retry_button_text'),
                        style: const TextStyle(color: KigoDesign.brand, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ],
                );
              },
            );
          }
        }
      }
    } else if (viewModel.pasoActual == PasoTouch.rostro) {
      bool esRostroValido = false;
      while (!esRostroValido) {
        if (!mounted) return;

        _speakText(AppLocalizations.t(context, 'voice_instruction_face'));
        final String? pathFoto = await Navigator.push<String>(
          context,
          MaterialPageRoute(builder: (_) => const EscaneoRostro()),
        );

        if (pathFoto == null) break;

        final bool exito = await viewModel.procesarEscaneoRostro(pathFoto);

        if (exito) {
          esRostroValido = true;
          if (mounted) _speakText(AppLocalizations.t(context, 'registration_complete_message'));
          if (viewModel.isLastStep) {
            _irACasaDestino();
          } else {
            viewModel.nextStep();
          }
        } else {
          if (mounted) {
            _speakText(AppLocalizations.t(context, 'face_not_detected_message'));
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return AlertDialog(
                  backgroundColor: context.kSurfaceCard,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  title: Row(
                    children: [
                      const Icon(Icons.face_retouching_off, color: KigoDesign.brand, size: 28),
                      const SizedBox(width: 12),
                      Flexible(child: Text(AppLocalizations.t(context, 'face_not_detected_title'), style: TextStyle(color: context.kTextPrimary))),
                    ],
                  ),
                  content: Text(
                    AppLocalizations.t(context, 'face_not_detected_content'),
                    style: TextStyle(color: context.kTextSecondary, fontSize: 16),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        AppLocalizations.t(context, 'retry_button_text'),
                        style: const TextStyle(color: KigoDesign.brand, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ],
                );
              },
            );
          }
        }
      }
    }
  }

  Future<void> _irACasaDestino() async {
    if (!mounted) return;
    final String? casa = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => CasaDestinoView(totalSteps: viewModel.indicatorTotalSteps),
      ),
    );
    if (casa == null) {
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    viewModel.registrationData.casaDestino = casa;

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

  @override
  Widget build(BuildContext context) {
    // Si el ViewModel no tiene pasos cargados aún, mostramos carga
    if (viewModel.steps.isEmpty) {
      return Scaffold(backgroundColor: context.kBg, body: Center(child: CircularProgressIndicator()));
    }

    final step = viewModel.currentStepData;

    return Scaffold(
      // Fondo unificado para toda la pantalla, en el tema que toque
      backgroundColor: context.kBg,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _buildVoiceWaveButton(),
      body: SizedBox.expand(
        //Expandimos a pantalla completa quitando Center y Container restrictivos
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  // incremente el padding vertical superior (60) e inferior (40) para proteger la legibilidad sin depender de SafeArea.
                  padding: const EdgeInsets.only(
                    left: 42,
                    right: 42,
                    top: 32,
                    bottom: 40,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
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

                      const SizedBox(height: 40),

                      StepIndicator(
                        currentStep: viewModel.indicatorStep,
                        totalSteps: viewModel.indicatorTotalSteps,
                      ),

                      const SizedBox(height: 44),

                      _buildVideoPlaceholder(),

                      const SizedBox(height: 64),

                      // --- BOTÓN PRINCIPAL CON LOADER ---
                      viewModel.isProcessingIne
                        ? const Center(child: CircularProgressIndicator(color: KigoDesign.brand))
                        : _buildMainButton(AppLocalizations.t(context, step.buttonTextKey)),

                      if (viewModel.currentStep > 1) ...[
                        const SizedBox(height: 16),
                        _buildBackButton(),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Leyenda fija hasta abajo de la pantalla, separada del borde.
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
    return GestureDetector(
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

  Widget _buildVideoPlaceholder() {
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
          child: viewModel.pasoActual == PasoTouch.ine
              ? const IneApproachAnimation()
              : const FaceApproachAnimation(),
        ),
      ),
    );
  }

  Widget _buildMainButton(String text) {
    return GestureDetector(
      onTap: _continueProcess,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: 260,
        height: 260,
        decoration: const BoxDecoration(
          color: KigoDesign.brand,
          shape: BoxShape.circle,
        ),
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
                    crossAxisAlignment: CrossAxisAlignment.center,
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
    return GestureDetector(
      onTap: viewModel.previousStep,
      child: Container(
        width: double.infinity,
        height: 62,
        decoration: BoxDecoration(
          color: context.kSurface2,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: context.kBorder,
            width: 1.2,
          ),
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
