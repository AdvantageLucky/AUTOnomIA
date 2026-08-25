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
import 'package:kigo_kiosco/l10n/app_localizations.dart';



class TouchRegisterView extends StatefulWidget {
  const TouchRegisterView({super.key});

  @override
  State<TouchRegisterView> createState() => _TouchRegisterViewState();
}

class _TouchRegisterViewState extends State<TouchRegisterView> {
  final TouchRegisterViewModel viewModel = TouchRegisterViewModel();
  final TextToSpeakServicio _textToSpeakServicio = TextToSpeakServicio();
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
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
  if (viewModel.isProcessingIne) return;

  // Si estamos en el paso de la INE (Paso 0)
    if (viewModel.currentStep == 0) {
      bool esIneValida = false;

        // Bucle/Ciclo: Mientras no sea un INE válido, seguirá pidiendo capturar
        while (!esIneValida) {
          if (!mounted) return;

          // 1. Abrir la cámara
          _speakText(AppLocalizations.t(context, 'voice_instruction_ine'));
          final String? pathFoto = await Navigator.push<String>(
            context,
            MaterialPageRoute(builder: (_) => const EscaneoInePage()), // Usa el nombre exacto de tu clase
          );

          // Si el usuario presiona el botón de regresar (cancela), rompemos el bucle
          if (pathFoto == null) break;

          // 2. Procesar con el ViewModel e IA local
          final bool exito = await viewModel.procesarEscaneoIne(pathFoto);

          if (exito) {
            esIneValida = true;
            _speakText(AppLocalizations.t(context, 'ine_detected_title'));
            viewModel.nextStep(); // Avanzamos al paso de la foto de rostro
          } else {
            // 3. Mostrar mensaje de error si no es un INE
            _speakText(AppLocalizations.t(context, 'ine_invalid_message'));
            if (mounted) {
              await showDialog(
                context: context,
                barrierDismissible: false, // Obliga a interactuar con el botón
                builder: (BuildContext context) {
                  return AlertDialog(
                    backgroundColor: const Color(0xFF211D1D),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    title: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Color(0xFFFF542F), size: 28),
                        const SizedBox(width: 12),
                        Flexible(child: Text(AppLocalizations.t(context, 'ine_invalid_error_title'), style: const TextStyle(color: Colors.white))),
                      ],
                    ),
                    content: Text(
                      AppLocalizations.t(context, 'ine_invalid_error_content'),
                      style: const TextStyle(color: Color(0xFFC5BFBF), fontSize: 16),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          AppLocalizations.t(context, 'retry_button_text'),
                          style: const TextStyle(color: Color(0xFFFF542F), fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ],
                  );
                },
              );
            }
            // Al no cumplirse 'esIneValida = true', el ciclo 'while' se repite
            // y vuelve a abrir la cámara inmediatamente tras cerrar la alerta.
          }
        }

    // Paso 1 - reconocimiento facial
    } else if (viewModel.currentStep == 1) {
      bool esRostroValido = false;

      // NUEVO: Mientras no se detecte un rostro válido, sigue pidiendo capturar
      while (!esRostroValido) {
        if (!mounted) return;

        _speakText(AppLocalizations.t(context, 'voice_instruction_face'));
        // NUEVO: 1. Abrir la cámara frontal
        final String? pathFoto = await Navigator.push<String>(
          context,
          MaterialPageRoute(builder: (_) => const EscaneoRostro()),
        );

        // NUEVO: Si el usuario cancela, rompemos el bucle
        if (pathFoto == null) break;

        // NUEVO: 2. Procesar con el ViewModel y el detector de rostros
        final bool exito = await viewModel.procesarEscaneoRostro(pathFoto);

        if (exito) {
          _speakText(AppLocalizations.t(context, 'registration_complete_message'));
          esRostroValido = true;
          // 3. Rostro válido -> pedimos casa y mostramos el resumen final.
          // Si el usuario da "atrás", cancelamos toda la solicitud y regresamos
          // al inicio del wizard (no hay a dónde "reanudar").
          if (!mounted) return;
          final String? casa = await Navigator.push<String>(
            context,
            MaterialPageRoute(builder: (_) => const CasaDestinoView()),
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
              ),
            ),
          );
        } else {
          // NUEVO: 4. Mostrar mensaje de error si no se detectó un rostro
          _speakText(AppLocalizations.t(context, 'face_not_detected_message'));
          if (mounted) {
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return AlertDialog(
                  backgroundColor: const Color(0xFF211D1D),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  title: Row(
                    children: [
                      const Icon(Icons.face_retouching_off, color: Color(0xFFFF542F), size: 28),
                      const SizedBox(width: 12),
                      Flexible(child: Text(AppLocalizations.t(context, 'face_not_detected_error_title'), style: const TextStyle(color: Colors.white))),
                    ],
                  ),
                  content: Text(
                    AppLocalizations.t(context, 'face_not_detected_error_content'),
                    style: const TextStyle(color: Color(0xFFC5BFBF), fontSize: 16),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        AppLocalizations.t(context, 'retry_button_text'),
                        style: const TextStyle(color: Color(0xFFFF542F), fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ],
                );
              },
            );
          }
          // NUEVO: Al no cumplirse 'esRostroValido = true', el ciclo 'while' se repite
          // y vuelve a abrir la cámara inmediatamente tras cerrar la alerta.
        }
      }
    }
}

  @override
  Widget build(BuildContext context) {
    // Si el ViewModel no tiene pasos cargados aún, mostramos carga
    if (viewModel.steps.isEmpty) {
      return const Scaffold(backgroundColor: KigoDesign.bgDark, body: Center(child: CircularProgressIndicator()));
    }

    final step = viewModel.currentStepData;

    return Scaffold(
      //Fondo negro unificado para toda la pantalla
      backgroundColor: KigoDesign.bgDark,
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
                        totalSteps: TouchRegisterViewModel.indicatorTotalSteps,
                      ),

                      const SizedBox(height: 44),

                      _buildVideoPlaceholder(),

                      const SizedBox(height: 64),

                      // --- BOTÓN PRINCIPAL CON LOADER ---
                      viewModel.isProcessingIne
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF542F)))
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
          color: KigoDesign.surface2,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: KigoDesign.textSecondary,
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
            color: const Color(0xFFFF542F),
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
          style: const TextStyle(
            color: Colors.white,
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
          color: const Color(0xFF0F0D0D),
          borderRadius: BorderRadius.circular(24),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(24)),
          child: viewModel.currentStep == 0
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
          color: Color(0xFFFF542F),
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
                    color: const Color(0xFFFF714D).withValues(alpha: 0.55),
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
        backgroundColor: const Color(0xFFFF542F),
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
          color: KigoDesign.surface2,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFF393333),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFFFF542F),
              size: 24,
            ),
            const SizedBox(width: 10),
            Text(
              AppLocalizations.t(context, 'back_button_text'),
              style: const TextStyle(
                color: Colors.white,
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
        color: KigoDesign.textTertiary,
        fontSize: 14,
        letterSpacing: 2,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
