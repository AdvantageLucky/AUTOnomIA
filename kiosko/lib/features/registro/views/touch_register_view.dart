import 'dart:math' as math;
import 'package:kigo_kiosco/core/services/asistente_controller.dart';
import 'package:kigo_kiosco/core/services/evidencia_calidad_servicio.dart';
import 'package:kigo_kiosco/core/theme/kigo_design.dart';
import 'package:kigo_kiosco/core/widgets/boton_asistente_flotante.dart';
import 'package:kigo_kiosco/core/widgets/presionable.dart';
import 'package:kigo_kiosco/features/registro/views/widgets/scanner_ine_widget.dart';
import 'package:kigo_kiosco/features/registro/views/widgets/ine_approach_animation.dart';
import 'package:kigo_kiosco/features/registro/views/widgets/face_approach_animation.dart';
import 'package:flutter/material.dart';
import 'package:kigo_kiosco/features/registro/models/paso_registro.dart';
import 'package:kigo_kiosco/features/registro/viewmodels/touch_register_viewmodel.dart';
import 'package:kigo_kiosco/features/registro/views/casa_destino_view.dart';
import 'package:kigo_kiosco/features/registro/views/resumen_solicitud_view.dart';
import 'package:kigo_kiosco/features/registro/views/widgets/step_indicator.dart';
import 'package:kigo_kiosco/features/registro/views/widgets/scanner_rostro_widget.dart';
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
  final AsistenteController _asistenteController = AsistenteController();

  @override
  void initState() {
    super.initState();
    viewModel = TouchRegisterViewModel(widget.config);
    viewModel.addListener(_refresh);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _narrar(AppLocalizations.t(context, 'welcome_message'));
      // El dashboard puede poner DESTINO de primero: en ese caso no hay nada
      // que capturar todavia y la pantalla arranca empujando su vista.
      _ejecutarSiEsAutomatico();
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

  // La presentación verbal única de la mascota ("Hola, soy tu
  // asistente...") vive en QrScannerView, la entrada real del kiosko —
  // para cuando el visitante llega aquí ya la vio.
  void _narrar(String texto) => _asistenteController.decir(texto);

  Future<void> _continueProcess() async {
    if (viewModel.isProcessingIne || viewModel.isProcessingRostro) return;

    if (viewModel.pasoActual == PasoRegistro.ine) {
      bool esIneValida = false;
      while (!esIneValida) {
        if (!mounted) return;

        _narrar(AppLocalizations.t(context, 'voice_instruction_ine'));
        final String? pathFoto = await Navigator.push<String>(
          context,
          MaterialPageRoute(builder: (_) => const EscaneoInePage()),
        );

        if (pathFoto == null) break;

        final CalidadCaptura resultado = await viewModel.procesarEscaneoIne(
          pathFoto,
        );
        if (resultado == CalidadCaptura.ok) {
          esIneValida = true;
          if (mounted) {
            _narrar(AppLocalizations.t(context, 'ine_detected_title'));
          }
          await _avanzar();
        } else {
          final esBorrosa = resultado == CalidadCaptura.borrosa;
          if (mounted) {
            _narrar(
              AppLocalizations.t(
                context,
                esBorrosa ? 'ine_borrosa_message' : 'ine_invalid_message',
              ),
            );
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return AlertDialog(
                  backgroundColor: context.kSurfaceCard,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  title: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: KigoDesign.brand,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          AppLocalizations.t(
                            context,
                            esBorrosa
                                ? 'ine_borrosa_error_title'
                                : 'ine_invalid_error_title',
                          ),
                          style: TextStyle(color: context.kTextPrimary),
                        ),
                      ),
                    ],
                  ),
                  content: Text(
                    AppLocalizations.t(
                      context,
                      esBorrosa
                          ? 'ine_borrosa_error_content'
                          : 'ine_invalid_error_content',
                    ),
                    style: TextStyle(
                      color: context.kTextSecondary,
                      fontSize: 16,
                    ),
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
                );
              },
            );
          }
        }
      }
    } else if (viewModel.pasoActual == PasoRegistro.rostro) {
      bool esRostroValido = false;
      while (!esRostroValido) {
        if (!mounted) return;

        _narrar(AppLocalizations.t(context, 'voice_instruction_face'));
        final String? pathFoto = await Navigator.push<String>(
          context,
          MaterialPageRoute(builder: (_) => const EscaneoRostro()),
        );

        if (pathFoto == null) break;

        final CalidadCaptura resultado = await viewModel.procesarEscaneoRostro(
          pathFoto,
        );

        if (resultado == CalidadCaptura.ok) {
          esRostroValido = true;
          if (mounted) {
            _narrar(
              AppLocalizations.t(context, 'registration_complete_message'),
            );
          }
          await _avanzar();
        } else {
          final esBorrosa = resultado == CalidadCaptura.borrosa;
          if (mounted) {
            _narrar(
              AppLocalizations.t(
                context,
                esBorrosa
                    ? 'face_borrosa_message'
                    : 'face_not_detected_message',
              ),
            );
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return AlertDialog(
                  backgroundColor: context.kSurfaceCard,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  title: Row(
                    children: [
                      const Icon(
                        Icons.face_retouching_off,
                        color: KigoDesign.brand,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          AppLocalizations.t(
                            context,
                            esBorrosa
                                ? 'face_borrosa_error_title'
                                : 'face_not_detected_title',
                          ),
                          style: TextStyle(color: context.kTextPrimary),
                        ),
                      ),
                    ],
                  ),
                  content: Text(
                    AppLocalizations.t(
                      context,
                      esBorrosa
                          ? 'face_borrosa_error_content'
                          : 'face_not_detected_content',
                    ),
                    style: TextStyle(
                      color: context.kTextSecondary,
                      fontSize: 16,
                    ),
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
                );
              },
            );
          }
        }
      }
    } else {
      // DESTINO no llega por el boton -- lo dispara _ejecutarSiEsAutomatico
      // al tocarle el turno. Se atiende igual por si el visitante alcanza a
      // tocar mientras se empuja la pantalla.
      await _ejecutarSiEsAutomatico();
    }
  }

  /// Cierra el paso actual: si era el ultimo va al resumen, si no avanza y
  /// deja corriendo el siguiente por si se resuelve solo.
  Future<void> _avanzar() async {
    if (viewModel.isLastStep) {
      _irAResumen();
      return;
    }
    viewModel.nextStep();
    await _ejecutarSiEsAutomatico();
  }

  /// DESTINO no espera un toque: empuja su pantalla en cuanto le toca. La
  /// recursion via _avanzar termina siempre, porque cada vuelta consume un
  /// paso de una lista finita.
  Future<void> _ejecutarSiEsAutomatico() async {
    if (!mounted || viewModel.pasos.isEmpty) return;
    if (!esPasoAutomatico(viewModel.pasoActual)) return;

    switch (viewModel.pasoActual) {
      case PasoRegistro.destino:
        await _pasoCasaDestino();
      // El flujo peatonal no lee placas; el viewmodel ya no arma ese paso.
      case PasoRegistro.placa:
      case PasoRegistro.ine:
      case PasoRegistro.rostro:
        break;
    }
  }

  Future<void> _pasoCasaDestino() async {
    if (!mounted) return;
    final resultado = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (_) => CasaDestinoView(
          currentStep: viewModel.indicatorStep,
          totalSteps: viewModel.indicatorTotalSteps,
          motivoHabilitado: viewModel.config.motivoObligatorioVisitante,
        ),
      ),
    );
    // Si da "atras" aqui se cancela toda la solicitud: no hay un punto
    // intermedio al que reanudar.
    final casa = resultado?['destino'];
    if (casa == null || casa.isEmpty) {
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    viewModel.registrationData.casaDestino = casa;
    viewModel.registrationData.motivo = resultado?['motivo'];
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

  @override
  Widget build(BuildContext context) {
    // Si el ViewModel no tiene pasos cargados aún, mostramos carga
    if (viewModel.steps.isEmpty) {
      return Scaffold(
        backgroundColor: context.kBg,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final step = viewModel.currentStepData;

    return Stack(
      children: [
        Scaffold(
          // Fondo unificado para toda la pantalla, en el tema que toque
          backgroundColor: context.kBg,
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

                          const SizedBox(height: 16),

                          StepIndicator(
                            currentStep: viewModel.indicatorStep,
                            totalSteps: viewModel.indicatorTotalSteps,
                          ),

                          const SizedBox(height: 24),

                          _buildVideoPlaceholder(),

                          const SizedBox(height: 32),

                          // --- BOTÓN PRINCIPAL CON LOADER ---
                          (viewModel.isProcessingIne || viewModel.isProcessingRostro)
                              ? _buildBotonCargando()
                              : _buildMainButton(
                                  AppLocalizations.t(
                                    context,
                                    step.buttonTextKey,
                                  ),
                                ),

                          if (viewModel.currentStep > 1) ...[
                            const SizedBox(height: 12),
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
        ),
        BotonAsistenteFlotante(
          // Coincide con el padding real de esta pantalla (top: 32,
          // right: 42 en el Padding de build()) para alinear con el
          // header real -- mismo criterio usado en Welcome/ConfirmarPlaca
          // esta sesión. Esta pantalla no usa SafeArea (a diferencia de
          // PantallaAdaptable) -- MediaQuery.paddingOf(context).top
          // debería ser 0 en el kiosko (modo inmersivo, sin status bar),
          // pero confirmar en dispositivo real que no desalinea el ícono.
          topDelBorde: 32,
          rightDelBorde: 42,
          mostrarEtiqueta: true,
          controlador: _asistenteController,
          onRespuestaLibre:
              (_) {}, // esta pantalla no usa Q&A libre por texto, solo narra
          onCampoExtraido: (_) {}, // no llena campos -- tipoCampo queda null
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

  Widget _buildVideoPlaceholder() {
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
              child: viewModel.pasoActual == PasoRegistro.ine
                  ? const IneApproachAnimation()
                  : const FaceApproachAnimation(),
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
      onTap: _continueProcess,
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
