import 'dart:math' as math;
import 'package:kigo_kiosco/core/services/asistente_controller.dart';
import 'package:kigo_kiosco/core/services/evidencia_calidad_servicio.dart';
import 'package:kigo_kiosco/core/theme/kigo_design.dart';
import 'package:kigo_kiosco/core/widgets/boton_asistente_flotante.dart';
import 'package:kigo_kiosco/core/widgets/hazard_stripe.dart';
import 'package:kigo_kiosco/core/widgets/marca_badge.dart';
import 'package:kigo_kiosco/core/widgets/presionable.dart';
import 'package:kigo_kiosco/features/registro/views/widgets/scanner_ine_widget.dart';
import 'package:kigo_kiosco/features/registro/views/widgets/ine_approach_animation.dart';
import 'package:kigo_kiosco/features/registro/views/widgets/face_approach_animation.dart';
import 'package:flutter/material.dart';
import 'package:kigo_kiosco/features/registro/models/paso_registro.dart';
import 'package:kigo_kiosco/features/registro/viewmodels/touch_register_viewmodel.dart';
import 'package:kigo_kiosco/features/registro/views/casa_destino_view.dart';
import 'package:kigo_kiosco/features/registro/views/motivo_view.dart';
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
      case PasoRegistro.motivo:
        await _pasoMotivo();
      // El flujo peatonal no lee placas; el viewmodel ya no arma ese paso.
      case PasoRegistro.placa:
      case PasoRegistro.ine:
      case PasoRegistro.rostro:
        break;
    }
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
    // Si da "atras" aqui se cancela toda la solicitud: no hay un punto
    // intermedio al que reanudar.
    if (casa == null) {
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    viewModel.registrationData.casaDestino = casa;
    await _avanzar();
  }

  Future<void> _pasoMotivo() async {
    if (!mounted) return;
    final String? motivo = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => MotivoView(
          currentStep: viewModel.indicatorStep,
          totalSteps: viewModel.indicatorTotalSteps,
        ),
      ),
    );
    if (motivo == null) {
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    viewModel.registrationData.motivo = motivo;
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
            child: Column(
              children: [
                // Bloque fijo de arriba: marca, regreso y barra de progreso.
                // Queda anclado para que el paso en curso siempre se lea a la
                // misma altura, aunque lo de abajo se acomode al centro.
                Padding(
                  padding: const EdgeInsets.only(left: 42, right: 42, top: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) => SizedBox(
                          width: double.infinity,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Reserva a los lados: a la izquierda el botón
                              // de regreso, a la derecha la mascota, que vive
                              // en otra capa del Stack de la pantalla y por
                              // eso no empuja a nadie. Con el logo y el título
                              // más grandes el título alcanzaba a meterse bajo
                              // la mascota; con este aire el FittedBox del
                              // header lo encoge un pelo antes de que pase.
                              // En un lienzo angosto (un teléfono, no el
                              // panel) la reserva cede: primero está que el
                              // header quepa.
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: _reservaLateral(
                                    constraints.maxWidth,
                                  ),
                                ),
                                child: _buildHeader(),
                              ),
                              Positioned(left: 0, child: _buildTopBackButton()),
                            ],
                          ),
                        ),
                      ),

                      // Antes 52, calibrado contra una mascota de 96: con ese
                      // hueco el indicador ya rozaba su caja, y al crecer la
                      // mascota a 116 se le habría metido dentro. Estos 72 lo
                      // dejan por debajo de la mascota completa (medido con
                      // tester.getRect en la prueba de layout).
                      const SizedBox(height: 72),

                      StepIndicator(
                        currentStep: viewModel.indicatorStep,
                        totalSteps: viewModel.indicatorTotalSteps,
                      ),
                    ],
                  ),
                ),

                // La animación y su CTA ya no cuelgan del indicador: se
                // reparten lo que queda de pantalla, que antes se quedaba
                // vacía abajo con todo amontonado arriba. La separación se
                // calcula en vez de fijarse, porque un padding fijo más un
                // Center dejaba el bloque descentrado (el piso se sumaba
                // sólo de un lado). Así la animación cae en el centro real
                // y la separación pedida sólo manda cuando ya no hay
                // espacio para centrar -- ahí entra el scroll y nada se
                // encima.
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final double separacion = math.max(
                        _separacionIndicadorAnimacion,
                        (constraints.maxHeight -
                                _margenInferior -
                                _altoBloqueCentral(
                                  constraints.maxWidth - _margenLateral * 2,
                                )) /
                            2,
                      );

                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: _margenLateral,
                            right: _margenLateral,
                            top: separacion,
                            bottom: _margenInferior,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _buildVideoPlaceholder(),

                              const SizedBox(height: _separacionAnimacionCta),

                              // --- BOTÓN PRINCIPAL CON LOADER ---
                              (viewModel.isProcessingIne ||
                                      viewModel.isProcessingRostro)
                                  ? _buildBotonCargando()
                                  : _buildMainButton(
                                      AppLocalizations.t(
                                        context,
                                        step.buttonTextKey,
                                      ),
                                    ),

                              if (viewModel.currentStep > 1) ...[
                                const SizedBox(height: _separacionBotonRegreso),
                                _buildBackButton(),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
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
          // +20 sobre la mascota estándar, por parámetro y no subiendo
          // KigoDesign.ladoAsistente: esa constante la comparten cinco
          // pantallas que calibran su contenido contra ella (welcome y
          // residentes ya crecen así, +10). El hueco del StepIndicator de
          // arriba está calculado contra este lado.
          lado: _ladoAsistente,
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
        // 44 + 20. El radio y la flecha suben en la misma proporción para
        // que siga siendo el mismo cuadro, no un cuadro grande con un
        // ícono chico adentro.
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: KigoDesign.brand,
          borderRadius: BorderRadius.circular(17),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 54 + 20. El nombre y la separación crecen en la misma proporción
        // que el isotipo: el header entero sube de escala, no sólo el
        // cuadrito.
        const MarcaBadge(lado: _ladoMarca),
        const SizedBox(width: 24),
        // En una pantalla más angosta que el panel el nombre desbordaba la
        // fila; encoge parejo con el logo en vez de recortarse.
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              AppLocalizations.t(context, 'kigo_label'),
              style: TextStyle(
                color: context.kTextPrimary,
                fontSize: 46,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoPlaceholder() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxH = _altoCajaAnimacion(constraints.maxWidth);
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
              // Las dos animaciones se dibujan a un tamaño fijo (el busto
              // mide 230x280, la credencial 260x164), así que subir la caja
              // sola las habría dejado igual de chicas con más aire vacío
              // alrededor. El FittedBox las escala a la caja conservando su
              // proporción -- crecen de verdad -- y el padding les deja el
              // aire para no llegar a tocar el borde redondeado.
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: viewModel.pasoActual == PasoRegistro.ine
                      ? const IneApproachAnimation()
                      : const FaceApproachAnimation(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBotonCargando() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        height: _altoBotonPrincipal,
        color: KigoDesign.bgDark,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: HazardStripeBar(
                height: 10,
                borderRadius: BorderRadius.zero,
              ),
            ),
            Text(
              AppLocalizations.t(context, 'procesando_captura'),
              style: TextStyle(
                fontFamily: 'Unbounded',
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Lado del isotipo del header: el de siempre (54) + 20.
  static const double _ladoMarca = 74;

  /// Mascota del asistente en esta pantalla: la estándar + 20.
  static const double _ladoAsistente = KigoDesign.ladoAsistente + 20;

  /// Aire que el header deja a cada lado para no cruzarse con lo que flota
  /// encima: el botón de regreso (64) a la izquierda y la mascota
  /// ([_ladoAsistente]) a la derecha, más un margen. Simétrico a propósito:
  /// así el logo sigue centrado en la pantalla y no contra el hueco libre.
  static const double _reservaLateralHeader = _ladoAsistente + 12;

  /// Ancho que el header necesita para no desbordar: isotipo + separación +
  /// un mínimo legible de nombre (el FittedBox lo encoge hasta ahí).
  static const double _anchoMinimoHeader = _ladoMarca + 24 + 120;

  /// La reserva completa sólo cabe en un panel; en un lienzo angosto se cede
  /// lo necesario para que el header entre, que es lo primero.
  static double _reservaLateral(double anchoDisponible) => math.min(
    _reservaLateralHeader,
    math.max(0, (anchoDisponible - _anchoMinimoHeader) / 2),
  );

  /// Alto máximo de la caja de la animación (antes 300). La animación se
  /// escala a esta caja, así que este número es lo que se ve crecer.
  static const double _altoAnimacion = 420;

  static const double _margenLateral = 42;
  static const double _margenInferior = 40;
  static const double _separacionAnimacionCta = 32;
  static const double _separacionBotonRegreso = 12;

  /// Alto de la caja de la animación con el ancho que le toque: en un panel
  /// ancho manda [_altoAnimacion], y en uno angosto la proporción, para que
  /// no se vuelva una banda desproporcionada.
  static double _altoCajaAnimacion(double anchoDisponible) =>
      math.min(anchoDisponible * 0.75, _altoAnimacion);

  /// Alto del bloque que se centra: animación + CTA (+ "Regresar" cuando
  /// toca). Se calcula aquí porque el centrado necesita saberlo ANTES de
  /// medirlo, y la prueba de layout verifica contra el árbol real que estas
  /// cuentas siguen coincidiendo.
  double _altoBloqueCentral(double anchoDisponible) =>
      _altoCajaAnimacion(anchoDisponible) +
      _separacionAnimacionCta +
      _altoBotonPrincipal +
      (viewModel.currentStep > 1
          ? _separacionBotonRegreso + _altoBotonRegreso
          : 0);

  /// Separación mínima entre la barra de progreso y la animación. Es un
  /// piso, no una medida fija: cuando sobra pantalla el bloque de abajo
  /// (animación + CTA) se centra en lo que queda y la separación crece
  /// parejo; en una pantalla corta se queda justo en estos 100.
  static const double _separacionIndicadorAnimacion = 100;

  /// Alto del CTA de abajo. Lo comparten el botón normal y su estado
  /// "procesando": si sólo cambiara uno, el botón se encogería a media
  /// captura.
  static const double _altoBotonPrincipal = 150;

  /// Alto del botón "Regresar" de abajo: 62 + 20.
  static const double _altoBotonRegreso = 82;

  Widget _buildMainButton(String text) {
    return Presionable(
      onTap: _continueProcess,
      child: Container(
        width: double.infinity,
        height: _altoBotonPrincipal,
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
            // Todo el contenido escala con el botón: pasó de 76 a 150 de
            // alto (x2), así que icono, textos y separaciones van al doble.
            // Con los tamaños viejos el texto quedaba flotando chiquito en
            // una caja del doble de grande.
            const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 56),
            const SizedBox(width: 28),
            Flexible(
              // La caja es de alto fijo, así que el texto no puede empujarla:
              // le toca a él caber. Sólo entra en acción con un texto más
              // largo que los de hoy (otro idioma, otro paso del alta).
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.t(context, 'continue_press_text'),
                      style: const TextStyle(
                        color: Color(0xFFFFE3DC),
                        fontSize: 26,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // La flecha también, al doble: acompaña al texto.
            const SizedBox(width: 20),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: 36,
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
        // 62 + 20, con el radio, el ícono y la letra a la misma escala: la
        // barra crece entera, no se estira.
        height: _altoBotonRegreso,
        decoration: BoxDecoration(
          color: context.kSurface2,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: context.kBorder, width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.arrow_back_rounded,
              color: KigoDesign.brand,
              size: 32,
            ),
            const SizedBox(width: 13),
            Text(
              AppLocalizations.t(context, 'back_button_text'),
              style: TextStyle(
                color: context.kTextPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
