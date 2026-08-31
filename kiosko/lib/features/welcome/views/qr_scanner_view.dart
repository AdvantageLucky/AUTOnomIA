import 'dart:async';
import 'dart:math' as math;

import 'package:kigo_kiosco/core/theme/kigo_design.dart';
import 'package:flutter/material.dart';
import 'package:kigo_kiosco/core/routing/observador_rutas.dart';
import 'package:kigo_kiosco/core/services/asistente_controller.dart';
import 'package:kigo_kiosco/core/services/asistente_presentacion_servicio.dart';
import 'package:kigo_kiosco/core/services/camara_kiosko.dart';
import 'package:kigo_kiosco/core/services/consentimiento_servicio.dart';
import 'package:kigo_kiosco/core/widgets/boton_asistente_flotante.dart';
import 'package:kigo_kiosco/core/widgets/etiqueta_asistente.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:kigo_kiosco/core/notifiers/kiosko_config_notifier.dart';
import 'package:kigo_kiosco/core/routing/registro_router.dart';
import 'package:kigo_kiosco/features/registro/services/kiosko_servicio.dart';
import 'package:kigo_kiosco/features/registro/views/widgets/consent_dialog.dart';
import 'package:kigo_kiosco/features/welcome/viewmodels/qr_scanner_viewmodel.dart';
import 'package:kigo_kiosco/features/welcome/viewmodels/qr_result_viewmodel.dart';
import 'package:kigo_kiosco/features/welcome/viewmodels/persona_qr_result_viewmodel.dart';
import 'package:kigo_kiosco/features/welcome/views/qr_result_view.dart';
import 'package:kigo_kiosco/features/welcome/views/persona_qr_result_view.dart';
import 'package:kigo_kiosco/features/welcome/views/widgets/comunidad_badge.dart';
import 'package:kigo_kiosco/features/welcome/views/widgets/kigo_wordmark.dart';
import 'package:kigo_kiosco/l10n/app_localizations.dart';

/// Lado del recuadro de escaneo como fracción del ancho.
const double _fraccionRecuadro = 0.66;

/// Lado del recuadro para un lienzo dado. Lo comparten el painter y el
/// layout: el texto se coloca respecto al recuadro real, así nunca vuelve a
/// montarse encima de él.
///
/// El tope contra el alto es para no quedarnos sin las dos franjas de
/// contenido: en un lienzo apaisado 0.66 del ancho no cabe siquiera en la
/// pantalla, y arriba y abajo sobraba espacio negativo.
double _ladoRecuadro(Size lienzo) =>
    math.min(lienzo.width * _fraccionRecuadro, lienzo.height * 0.45);

/// Pantalla de entrada del kiosko: escanea sola, sin toque previo. Detecta
/// tanto el QR personal de la app Kigo como el token de invitación de
/// siempre. [onSinCodigo] es la única salida — quien no trae ningún código
/// cae al flujo manual existente.
class QrScannerView extends StatefulWidget {
  final QrScannerViewModel viewModel;
  final VoidCallback onSinCodigo;

  const QrScannerView({
    super.key,
    required this.viewModel,
    required this.onSinCodigo,
  });

  @override
  State<QrScannerView> createState() => _QrScannerViewState();
}

class _QrScannerViewState extends State<QrScannerView>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver, RouteAware {
  bool _consentGiven = false;
  bool _readyToScan = false;
  bool _botonPresionado = false;
  MobileScannerController? _controller;
  late final AnimationController _anilloCtrl;
  final AsistenteController _asistenteController = AsistenteController();

  /// Espera entre detectar el código y navegar al resultado. Se guarda para
  /// poder cancelarla: si la pantalla muere antes, navegar desde un State ya
  /// desechado deja la app colgada.
  Timer? _timerNavegacion;

  /// Campo de texto invisible que capta al lector QR dedicado del hardware
  /// Telpo F10 — opera como teclado-wedge (HID): al escanear, escribe el
  /// contenido en cualquier campo enfocado, sin Intent ni binding de SDK.
  /// Coexiste con `MobileScanner`; el que detecte primero gana (dedup ya
  /// existe en el viewmodel vía `isScanned`).
  final _lectorFisicoController = TextEditingController();
  final _lectorFisicoFocus = FocusNode();

  /// El lector no manda Enter al terminar — se detecta el fin del escaneo
  /// por quietud: si no llega texto nuevo en este lapso, se toma lo
  /// acumulado como el QR completo.
  static const _debounceLectorFisico = Duration(milliseconds: 250);
  Timer? _timerLectorFisico;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.viewModel.addListener(_updateView);
    // Pantalla de entrada, siempre remontada de cero para cada visitante
    // nuevo: el consentimiento de la persona anterior no aplica aquí.
    ConsentimientoServicio.reiniciar();
    _anilloCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _lectorFisicoController.addListener(_onLectorFisicoCambio);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _solicitarConsentimiento();
      _presentarAsistenteSiCorresponde();
    });
  }

  /// Esta pantalla es la entrada real del kiosko -- el 100% de los
  /// visitantes pasa por aquí antes que por cualquier flujo de registro. La
  /// presentación verbal única de la mascota ("Hola, soy tu asistente...")
  /// vive aquí y no en los pasos de registro, para que se entienda desde el
  /// primer momento que hay un asistente al que se le puede hablar.
  void _presentarAsistenteSiCorresponde() {
    if (AsistentePresentacionServicio.yaPresentado) return;
    AsistentePresentacionServicio.marcarPresentado();
    _asistenteController.decir(
      AppLocalizations.t(context, 'asistente_presentacion_message'),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ruta = ModalRoute.of(context);
    if (ruta is PageRoute) observadorDeRutas.subscribe(this, ruta);
  }

  @override
  void dispose() {
    _timerNavegacion?.cancel();
    _timerLectorFisico?.cancel();
    observadorDeRutas.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    widget.viewModel.removeListener(_updateView);
    _anilloCtrl.dispose();
    _controller?.dispose();
    _lectorFisicoController.dispose();
    _lectorFisicoFocus.dispose();
    super.dispose();
  }

  /// Otra vista se abrió encima. Esta pantalla es el `home` de la app y las
  /// demás llegan con `push`, así que sigue montada y reteniendo la cámara.
  /// Hay que soltarla: el kiosko tiene una sola y el flujo de registro la
  /// necesita para el INE y el rostro.
  @override
  void didPushNext() => _liberarCamara();

  /// Volvimos a quedar visibles.
  @override
  void didPopNext() {
    if (_consentGiven) _crearControlador();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_consentGiven) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _liberarCamara();
    } else if (state == AppLifecycleState.resumed) {
      // Si hay otra vista encima, la cámara le toca a ella. El `mounted` no
      // es opcional: consultar ModalRoute desde un widget desactivado lanza
      // "Looking up a deactivated widget's ancestor is unsafe".
      if (!mounted) return;
      if (ModalRoute.of(context)?.isCurrent ?? false) _crearControlador();
    }
  }

  /// Crea un controlador nuevo en lugar de reanudar el anterior.
  ///
  /// Sobre este HAL un `start()` después de un `stop()` deja la vista previa
  /// congelada; abrir una sesión limpia es lo único que se recupera de forma
  /// fiable. De paso limpia el caché de `noDuplicates`.
  void _crearControlador() {
    if (!mounted || _controller != null) return;
    setState(() {
      // Se deja la selección por defecto (CameraFacing.back): este panel
      // reporta su lente RGB como trasera y la IR como frontal, al revés de lo
      // que sugiere que sea un equipo de pared. Forzar `front` abría la IR.
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
      );
      _readyToScan = true;
    });
    // Mismo momento en que arranca la cámara: el lector físico dedicado
    // (teclado-wedge) solo debe recibir foco mientras esta pantalla está
    // realmente activa y lista, igual que la cámara.
    _lectorFisicoFocus.requestFocus();
  }

  void _liberarCamara() {
    final viejo = _controller;
    if (viejo == null) return;
    if (mounted) {
      setState(() {
        _controller = null;
        _readyToScan = false;
      });
    } else {
      _controller = null;
      _readyToScan = false;
    }
    viejo.dispose();
    _timerLectorFisico?.cancel();
    _lectorFisicoFocus.unfocus();
  }

  /// El lector no manda Enter al terminar: se espera a que el campo quede
  /// quieto (sin texto nuevo) por `_debounceLectorFisico` antes de tratar lo
  /// acumulado como un QR completo.
  void _onLectorFisicoCambio() {
    if (_lectorFisicoController.text.isEmpty) return;
    _timerLectorFisico?.cancel();
    _timerLectorFisico = Timer(_debounceLectorFisico, () {
      final valor = _lectorFisicoController.text;
      _lectorFisicoController.clear();
      if (valor.isEmpty || !_readyToScan) return;
      _onQrDetected(valor);
    });
  }

  void _updateView() => setState(() {});

  Future<void> _solicitarConsentimiento() async {
    final bool aceptado = await mostrarConsentimientoCamara(context);
    if (!mounted) return;
    if (aceptado) {
      ConsentimientoServicio.otorgar();
      setState(() => _consentGiven = true);
      _crearControlador();
    } else {
      // No hay a dónde regresar — es la pantalla de entrada. Reintentamos el
      // consentimiento en vez de dejar al kiosko sin nada que mostrar.
      _solicitarConsentimiento();
    }
  }

  void _onQrDetected(String value) {
    if (widget.viewModel.isScanned) return;
    widget.viewModel.onQrDetected(value);
    _liberarCamara();

    final navigator = Navigator.of(context);

    // El QR personal de la app Kigo (persona_id:firma) siempre identifica
    // por completo a quien lo trae — a diferencia del token de invitación,
    // no hay reglas de captura del kiosko que aplicarle.
    if (value.contains(':')) {
      _timerNavegacion = Timer(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        navigator.pushReplacement(
          MaterialPageRoute(
            builder: (_) => PersonaQrResultView(
              viewModel: PersonaQrResultViewModel(qrValue: value),
              alTerminar: () => _reiniciar(navigator),
            ),
          ),
        );
      });
      return;
    }

    final config = context.read<KioskoConfigNotifier>().config;

    // Si la config no pide capturas al invitado, el QR basta: se consume la
    // invitación de inmediato como siempre.
    if (!RegistroRouter.invitadoRequiereCapturas(config)) {
      _timerNavegacion = Timer(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        navigator.pushReplacement(
          MaterialPageRoute(
            builder: (_) => QrResultView(
              viewModel: QrResultViewModel(token: value),
              alTerminar: () => _reiniciar(navigator),
            ),
          ),
        );
      });
      return;
    }

    _continuarConCapturas(value);
  }

  /// Vuelve a montar la pantalla de escaneo desde cero para el siguiente
  /// visitante — cada persona da su propio consentimiento de cámara.
  void _reiniciar(NavigatorState navigator) {
    // Se usa el navegador global y no el context de esta pantalla: cuando esto
    // corre, este State ya fue desechado por el pushReplacement anterior.
    (navegadorKigo.currentState ?? navigator).pushReplacement(
      MaterialPageRoute(
        builder: (_) => QrScannerView(
          viewModel: QrScannerViewModel(),
          onSinCodigo: widget.onSinCodigo,
        ),
      ),
    );
  }

  /// El invitado tiene que dejar evidencia (placa, rostro o INE) antes de que la
  /// invitación se consuma. Se valida el token primero para no mandarlo a tomar
  /// fotos si el QR ya venció, y para saber a nombre de quién va la visita.
  Future<void> _continuarConCapturas(String token) async {
    final config = context.read<KioskoConfigNotifier>().config;
    final servicio = context.read<KioskoServicio>();
    final navigator = Navigator.of(context);

    try {
      final invitacion = await servicio.validarInvitacion(token);
      if (!mounted) return;

      navigator.pushReplacement(
        MaterialPageRoute(
          builder: (_) => RegistroRouter.paraInvitado(
            config,
            token: token,
            titular: invitacion['titular'] as String?,
            casaDestino: invitacion['casa_destino'] as String?,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      // QrResultView ya sabe mostrar el error de una invitación inválida.
      navigator.pushReplacement(
        MaterialPageRoute(
          builder: (_) => QrResultView(
            viewModel: QrResultViewModel(token: token),
            alTerminar: () => _reiniciar(navigator),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mismo mensaje que rotula la pantalla de bienvenida: sale del dashboard
    // (`mensaje_bienvenida`) y es lo que le dice al visitante en dónde está.
    final mensaje = context
        .watch<KioskoConfigNotifier>()
        .config
        .mensajeBienvenida
        .trim();

    // Geometría del recuadro, calculada igual que en el painter. Se saca del
    // MediaQuery y no de un LayoutBuilder a propósito: el builder corre en la
    // fase de layout, y los hijos animados de aquí (AnimatedSwitcher,
    // AnimatedContainer) llaman setState al reconstruirse -> "Build scheduled
    // during frame". Con resizeToAvoidBottomInset en false el cuerpo mide
    // siempre la pantalla completa, que es sobre lo que pinta el painter.
    final pantalla = MediaQuery.sizeOf(context);
    final safe = MediaQuery.paddingOf(context);
    final lado = _ladoRecuadro(pantalla);
    final topRecuadro = ((pantalla.height - lado) / 2).clamp(
      0.0,
      pantalla.height,
    );
    final bottomRecuadro = (topRecuadro + lado).clamp(0.0, pantalla.height);

    return Scaffold(
      // Fuera del recuadro no se ve la vista previa: el fondo del Scaffold y
      // el velo del painter son el mismo color del tema, para que el modo
      // claro no deje un marco negro alrededor del encuadre.
      backgroundColor: context.kBg,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Invisible: solo existe para que el lector QR dedicado del F10
          // (teclado-wedge) tenga un campo enfocado donde "teclear" el
          // contenido escaneado. `TextInputType.none` evita que Android
          // muestre el teclado virtual al enfocarlo.
          Positioned(
            left: -1000,
            top: -1000,
            child: SizedBox(
              width: 1,
              height: 1,
              child: TextField(
                controller: _lectorFisicoController,
                focusNode: _lectorFisicoFocus,
                autofocus: false,
                showCursor: false,
                keyboardType: TextInputType.none,
                decoration: const InputDecoration.collapsed(hintText: null),
              ),
            ),
          ),

          if (_consentGiven && _controller != null)
            // mobile_scanner tampoco acierta la orientación en este panel: se
            // le aplica el mismo giro fijo que al resto de las cámaras.
            Positioned.fill(
              child: RotatedBox(
                quarterTurns: AjustesCamara.cuartosDeGiro,
                child: MobileScanner(
                  controller: _controller!,
                  onDetect: (capture) {
                    if (!_readyToScan) return;
                    final barcode = capture.barcodes.firstOrNull;
                    final value = barcode?.rawValue;
                    if (value != null) _onQrDetected(value);
                  },
                ),
              ),
            ),

          Positioned.fill(
            child: AnimatedBuilder(
              animation: _anilloCtrl,
              builder: (context, _) => CustomPaint(
                painter: _QrOverlayPainter(
                  scanned: widget.viewModel.isScanned,
                  pulso: _anilloCtrl.value,
                  colorVelo: context.kBg,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),

          // El contenido se ancla al recuadro y no a un `Spacer`: el
          // painter pinta sobre la pantalla completa y repartir el sobrante a
          // ojo terminaba con el texto encima del encuadre.

          // Franja de arriba: la marca pegada al borde y el mensaje del
          // dashboard a media altura entre ella y el recuadro.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topRecuadro,
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, safe.top + 24, 24, 20),
              child: Column(
                children: [
                  const KigoWordmark(escala: 1.7),
                  Expanded(
                    child: Center(
                      child: mensaje.isEmpty
                          ? const SizedBox.shrink()
                          : FittedBox(
                              fit: BoxFit.scaleDown,
                              child: SizedBox(
                                width: pantalla.width - 48,
                                // El `Center` deja que la pastilla se ajuste al
                                // texto en vez de estirarse a todo el ancho.
                                child: Center(
                                  child: ComunidadBadge(
                                    mensaje: mensaje,
                                    escala: 1.7,
                                    envolverTexto: true,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Franja de abajo: arranca donde termina el recuadro. El
          // `FittedBox` es el seguro de vida del layout: los tamaños están
          // pensados para el panel de 800x1280 y en una pantalla más corta el
          // bloque no cabría bajo el recuadro. Antes eso reventaba en un
          // overflow de RenderFlex por cuadro; ahora simplemente se escala.
          Positioned(
            top: bottomRecuadro,
            left: 0,
            right: 0,
            bottom: 0,
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 32, 24, safe.bottom + 28),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: SizedBox(
                  width: pantalla.width - 48,
                  child: _buildBottomHint(),
                ),
              ),
            ),
          ),

          // Mismo padding top que el KigoWordmark de la franja de arriba
          // (24 + safe area) para que quede a su misma altura, a la derecha.
          BotonAsistenteFlotante(
            topDelBorde: 24,
            rightDelBorde: 24,
            controlador: _asistenteController,
            onRespuestaLibre: (_) {},
            onCampoExtraido: (_) {},
          ),
          Positioned(
            top: 24 + KigoDesign.offsetEtiquetaAsistente + safe.top,
            right: 24,
            child: const EtiquetaAsistente(),
          ),
        ],
      ),
    );
  }

  /// Tipografía de kiosko: esto se lee de pie y a un brazo de distancia, no
  /// con el teléfono en la mano.
  Widget _buildBottomHint() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            widget.viewModel.isScanned
                ? AppLocalizations.t(context, 'codigo_detectado')
                : AppLocalizations.t(context, 'apunta_al_codigo_qr'),
            key: ValueKey(widget.viewModel.isScanned),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: widget.viewModel.isScanned
                  ? KigoDesign.success
                  : context.kTextPrimary,
              fontSize: 34,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          AppLocalizations.t(context, 'codigo_personal_o_invitacion'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.kTextSecondary,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 40),
        _buildBotonSinCodigo(),
      ],
    );
  }

  /// Acción primaria de quien llega sin QR — mismo naranja y mismo resplandor
  /// que los botones de la pantalla de bienvenida.
  Widget _buildBotonSinCodigo() {
    return GestureDetector(
      onTapDown: (_) => setState(() => _botonPresionado = true),
      onTapUp: (_) {
        setState(() => _botonPresionado = false);
        widget.onSinCodigo();
      },
      onTapCancel: () => setState(() => _botonPresionado = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 26),
        decoration: BoxDecoration(
          color: _botonPresionado ? KigoDesign.brandHover : KigoDesign.brand,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: KigoDesign.brandHover, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: KigoDesign.brand.withValues(
                alpha: _botonPresionado ? 0.45 : 0.28,
              ),
              blurRadius: _botonPresionado ? 30 : 22,
              spreadRadius: _botonPresionado ? 2 : 0,
            ),
          ],
        ),
        child: Text(
          AppLocalizations.t(context, 'no_tengo_app_o_qr'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

/// El motivo de firma de todo el flujo QR: un solo anillo continuo que
/// respira mientras espera (en vez del típico marco de esquinas) y se cierra
/// en un gesto rápido y sin rebote al detectar un código — mismo lenguaje
/// visual que retoman las pantallas de resultado.
class _QrOverlayPainter extends CustomPainter {
  final bool scanned;
  final double pulso;

  /// Color con el que se tapa todo lo que queda fuera del encuadre. Lo pone
  /// quien construye el painter a partir del tema activo.
  final Color colorVelo;

  const _QrOverlayPainter({
    required this.scanned,
    required this.pulso,
    required this.colorVelo,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Sólido, no translúcido: fuera del recuadro no se ve nada de la vista
    // previa. Deja el encuadre como único punto de atención y evita que la
    // sala de fondo compita con el texto.
    final overlayPaint = Paint()..color = colorVelo;

    final cutBase = _ladoRecuadro(size);
    // Respiración sutil (0.97–1.0) mientras espera; sólido y estable ya detectado.
    final escala = scanned ? 1.0 : 0.97 + (0.03 * pulso);
    final cutSize = cutBase * escala;
    final left = (size.width - cutSize) / 2;
    final top = (size.height - cutSize) / 2;
    final rect = Rect.fromLTWH(left, top, cutSize, cutSize);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(28));

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, overlayPaint);

    final color = scanned ? KigoDesign.success : KigoDesign.brand;
    final opacidadAnillo = scanned ? 1.0 : 0.55 + (0.35 * pulso);

    // Resplandor suave detrás del anillo — la profundidad que separa esto de
    // un simple marco plano.
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.35 * opacidadAnillo)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawRRect(rrect, glowPaint);

    final ringPaint = Paint()
      ..color = color.withValues(alpha: opacidadAnillo)
      ..style = PaintingStyle.stroke
      ..strokeWidth = scanned ? 3.5 : 2.5;
    canvas.drawRRect(rrect, ringPaint);
  }

  @override
  bool shouldRepaint(_QrOverlayPainter oldDelegate) =>
      oldDelegate.scanned != scanned ||
      oldDelegate.pulso != pulso ||
      oldDelegate.colorVelo != colorVelo;
}
