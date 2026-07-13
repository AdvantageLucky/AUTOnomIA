/* VISTA PRINCIPAL DE REGISTRO TÁCTIL */

import 'dart:io'; // Para File()
import 'package:kigo_kiosco/features/registro/views/widgets/scanner_ine_widget.dart';
import 'package:flutter/material.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:kigo_kiosco/features/registro/viewmodels/touch_register_viewmodel.dart';
import 'package:kigo_kiosco/features/registro/views/confirm_data_view.dart';
import 'package:kigo_kiosco/features/registro/views/widgets/step_indicator.dart';
import 'package:kigo_kiosco/features/registro/views/widgets/scanner_rostro_widget.dart';
import 'package:kigo_kiosco/core/services/text_to_speak_servicio.dart';
import 'package:kigo_kiosco/core/agent/consts.dart';



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
      _speakText(welcomeMessage);
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
          // 1. Abrir la cámara
          _speakText(voiceInstructionIne);
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
            _speakText(ineDetectedTitle);
            viewModel.nextStep(); // Avanzamos al paso de la foto de rostro
          } else {
            // 3. Mostrar mensaje de error si no es un INE
            _speakText(ineInvalidMessage);
            if (mounted) {
              await showDialog(
                context: context,
                barrierDismissible: false, // Obliga a interactuar con el botón
                builder: (BuildContext context) {
                  return AlertDialog(
                    backgroundColor: const Color(0xFF211D1D),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    title: const Row(
                      children: [
                        Icon(Icons.error_outline_rounded, color: Color(0xFFFF542F), size: 28),
                        SizedBox(width: 12),
                        Text(ineInvalidErrorTitle, style: TextStyle(color: Colors.white)),
                      ],
                    ),
                    content: const Text(
                      ineInvalidErrorContent,
                      style: TextStyle(color: Color(0xFFC5BFBF), fontSize: 16),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          retryButtonText,
                          style: TextStyle(color: Color(0xFFFF542F), fontWeight: FontWeight.bold, fontSize: 16),
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
        _speakText(voiceInstructionFace);
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
          _speakText(registrationCompleteMessage);
          esRostroValido = true;
          // NUEVO: 3. Rostro válido -> navegamos a la vista de confirmación
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ConfirmDataView(
                  registrationData: viewModel.registrationData,
                ),
              ),
            );
          }
        } else {
          // NUEVO: 4. Mostrar mensaje de error si no se detectó un rostro
          _speakText(faceNotDetectedMessage);
          if (mounted) {
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return AlertDialog(
                  backgroundColor: const Color(0xFF211D1D),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  title: const Row(
                    children: [
                      Icon(Icons.face_retouching_off, color: Color(0xFFFF542F), size: 28),
                      SizedBox(width: 12),
                      Text(faceNotDetectedErrorTitle, style: TextStyle(color: Colors.white)),
                    ],
                  ),
                  content: const Text(
                    faceNotDetectedErrorContent,
                    style: TextStyle(color: Color(0xFFC5BFBF), fontSize: 16),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        retryButtonText,
                        style: TextStyle(color: Color(0xFFFF542F), fontWeight: FontWeight.bold, fontSize: 16),
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
      return const Scaffold(backgroundColor: Color(0xFF171313), body: Center(child: CircularProgressIndicator()));
    }

    final step = viewModel.currentStepData;

    return Scaffold(
      //Fondo negro unificado para toda la pantalla
      backgroundColor: const Color(0xFF171313),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _buildVoiceWaveButton(),
      body: SizedBox.expand(
        //Expandimos a pantalla completa quitando Center y Container restrictivos
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            // incremente el padding vertical superior (60) e inferior (40) para proteger la legibilidad sin depender de SafeArea.
            padding: const EdgeInsets.only(
              left: 42,
              right: 42,
              top: 60,
              bottom: 40,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildHeader(),

                const SizedBox(height: 40),

                StepIndicator(
                  currentStep: viewModel.indicatorStep,
                  totalSteps: TouchRegisterViewModel.indicatorTotalSteps,
                ),

                const SizedBox(height: 44),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    step.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    step.subtitle,
                    style: const TextStyle(
                      color: Color(0xFF999494),
                      fontSize: 21,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),

                const SizedBox(height: 34),

                _buildInstructionCard(
                  icon: step.icon,
                  description: step.description,
                ),

                const SizedBox(height: 28),

                _buildPreviewBox(),

                const SizedBox(height: 28),

                // --- BOTÓN PRINCIPAL CON LOADER ---
                viewModel.isProcessingIne
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF542F)))
                  : _buildMainButton(step.buttonText),

                if (viewModel.currentStep > 1) ...[
                  const SizedBox(height: 16),
                  _buildBackButton(),
                ],

                const SizedBox(height: 36),

                _buildFooter(),
              ],
            ),
          ),
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
        const Text(
          kigoLabel,
          style: TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionCard({
    required IconData icon,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: const Color(0xFF211D1D),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF2F2929),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF3A2420),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              icon,
              color: const Color(0xFFFF542F),
              size: 36,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(
                color: Color(0xFFC5BFBF),
                fontSize: 18,
                height: 1.45,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewBox() {
    String title = instructionAreaCapture;
    String subtitle = instructionCameraPreview;
    IconData icon = Icons.camera_alt_outlined;
    Widget content;

    // Lógica visual basada en el estado del ViewModel
    if (viewModel.currentStep == 0) {
      // Estamos en el paso de escaneo
      if (viewModel.registrationData.pathFotoIne != null) {
        // YA SE ESCANEÓ: Mostramos la foto real
        title = ineDetectedTitle;
        subtitle = 'CURP: ${viewModel.registrationData.curp ?? noLeida}\nClave: ${viewModel.registrationData.claveElector ?? noLeida}';
        icon = Icons.check_circle_outline;

        content = ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.file(
            File(viewModel.registrationData.pathFotoIne!),
            width: double.infinity,
            height: 190,
            fit: BoxFit.cover,
          ),
        );
      } else {
        // NO SE HA ESCANEADO AÚN: Mostramos la guía visual por defecto
        title = ineTitle;
        subtitle = ineSubtitle;
        icon = Icons.badge_outlined;

        content = Stack(
          children: [
            Center(
              child: Container(
                width: 260,
                height: 118,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFFF542F).withValues(alpha: 0.7),
                    width: 2,
                  ),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: const Color(0xFFFF542F), size: 40),
                  const SizedBox(height: 12),
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF8A8585), fontSize: 15)),
                ],
              ),
            ),
          ],
        );
      }
    } else if (viewModel.currentStep == 1) {
      // Lógica para el paso de rostro, similar a la anterior...
      title = photoEvidenceTitle;
      subtitle = photoEvidenceSubtitle;
      icon = Icons.photo_camera_outlined;
      content = Container(); // Placeholder
    } else {
      // Placeholder para otros pasos
      content = Container();
    }

    return Container(
      width: double.infinity,
      height: 190,
      decoration: BoxDecoration(
        color: const Color(0xFF0F0D0D),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF363030),
          width: 1.2,
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Container(
              width: 260,
              height: 118,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFFF542F).withValues(alpha: 0.7),
                  width: 2,
                ),
              ),
            ),
          ),
          Center(
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildMainButton(String text) {
    final String buttonText =
        viewModel.isLastStep ? continueButtonText : text;

    return GestureDetector(
      onTap: _continueProcess,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: double.infinity,
        height: 104,
        decoration: BoxDecoration(
          color: const Color(0xFFFF542F),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -18,
              top: -32,
              child: Container(
                width: 135,
                height: 135,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF714D).withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Row(
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      viewModel.isLastStep
                          ? Icons.check_rounded
                          : Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          buttonText,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          continuePressText,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFFFFE3DC),
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceWaveButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0, right: 20.0),
      child: FloatingActionButton(
        onPressed: _isSpeaking ? null : () => _speakText(listeningMessage),
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
          color: const Color(0xFF2B2727),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFF393333),
            width: 1.2,
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFFFF542F),
              size: 24,
            ),
            SizedBox(width: 10),
            Text(
              backButtonText,
              style: TextStyle(
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
    return const Text(
      footerText,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Color(0xFF595252),
        fontSize: 14,
        letterSpacing: 2,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
