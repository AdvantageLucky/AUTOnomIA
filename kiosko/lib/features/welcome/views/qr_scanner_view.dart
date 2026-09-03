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
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:kigo_kiosco/core/notifiers/kiosko_config_notifier.dart';
import 'package:kigo_kiosco/core/routing/registro_router.dart';
import 'package:kigo_kiosco/core/services/led_servicio.dart';
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
///
/// Antes 0.66: el recuadro (centrado verticalmente) se comía tanto alto que
/// a la franja de abajo ("Apunta al código QR" + botón "No tengo la app")
/// le quedaba una banda angosta -- medido con un RenderParagraph de esa
/// franja contra su rect ya escalado, el FittedBox que la envuelve la
/// reducía a ~40% de su tamaño real. Bajarlo a 0.5 (siguen siendo ~400px de
/// lado en el panel de 800x1280, de sobra para leer un QR a un brazo de
/// distancia) le devuelve a esa franja el espacio que necesita para
/// renderizarse a tamaño completo.
///
/// 0.5375 son 430px clavados en el panel de 800x1280, que es la medida
/// pedida; sigue siendo una fracción y no un número fijo para que el
/// recuadro se adapte a otros lienzos.
const double _fraccionRecuadro = 0.5375;

/// Lado del recuadro para un lienzo dado.
///
/// El tope contra el alto es para no quedarnos sin las dos franjas de
/// contenido: en un lienzo apaisado 0.5 del ancho no cabe siquiera en la
/// pantalla, y arriba y abajo sobraba espacio negativo.
double _ladoRecuadro(Size lienzo) => math.min(
      _ladoRecuadroPedido,
      math.min(lienzo.width * _fraccionRecuadro, lienzo.height * 0.38),
    );

/// La medida pedida para el panel, en píxeles lógicos y no como fracción.
///
/// La fracción sola daba 430 sólo si el lienzo mide exactamente 800 de ancho;
/// en cualquier otro el recuadro salía de otro tamaño y parecía que el cambio
/// no se había aplicado. Con el tope, 430 son 430 mientras quepan, y la
/// fracción sigue mandando en lienzos más chicos.
const double _ladoRecuadroPedido = 430.0;

/// Qué parte del sobrante vertical va ARRIBA del recuadro.
///
/// Era 0.32. Con el bloque de abajo anclado a los botones flotantes, el
/// recuadro y sus textos bajan: el sobrante que eso libera se va todo a la
/// franja de arriba, que es donde vive la pastilla del mensaje.
const double _fraccionTopRecuadro = 0.48;

/// Hueco que ocupa el recuadro de escaneo en un lienzo dado: la única fuente
/// de verdad de esa geometría.
///
/// La comparten el layout (que cuelga las dos franjas de texto de sus bordes)
/// y el painter (que recorta el velo y dibuja el anillo ahí). Antes cada uno
/// la calculaba por su lado y se salieron de sincronía: el layout subía el
/// recuadro al 32% del sobrante y el painter lo centraba, así que en el panel
/// de 800x1280 el anillo caía 158px más abajo de lo que el layout creía y
/// "Apunta al código QR" terminaba dibujado adentro del encuadre.
///
/// No va centrado en vertical: a la franja de abajo (texto + botón "no tengo
/// la app") le hace falta más alto que a la de arriba (solo la marca), así que
/// el recuadro se sube en vez de repartir el sobrante a la mitad. El piso de
/// 100 es lo que la marca (KigoWordmark, fija, no Expanded) necesita para no
/// desbordar en un lienzo apaisado bajito -- por debajo de eso el Column de la
/// franja de arriba revienta (RenderFlex overflow), confirmado con
/// qr_scanner_layout_test en Size(784, 361).
Rect rectRecuadroQr(Size lienzo) {
  final lado = _ladoRecuadro(lienzo);
  final top = math
      .max((lienzo.height - lado) * _fraccionTopRecuadro, 100.0)
      .clamp(0.0, lienzo.height);
  return Rect.fromLTWH((lienzo.width - lado) / 2, top, lado, lado);
}

/// Alto del CTA "no tengo la app". Va fijo y no calculado desde el padding:
/// la medida es un requisito de diseño (750x100 en el panel) y derivarla del
/// texto la dejaba a merced de cuántos renglones ocupe la frase en cada
/// idioma.
const double _altoBotonSinCodigo = 100;

/// Ancho pedido para el CTA. Mismo motivo que [_ladoRecuadroPedido]: derivarlo
/// del ancho del lienzo sólo daba 750 en un panel de 800.
const double _anchoBotonPedido = 750.0;

/// Aire entre el CTA y los botones flotantes de abajo.
const double _huecoCtaBotonesFlotantes = 10.0;

/// Margen lateral de la franja de arriba, y por lo tanto lo unico que le
/// queda por crecer a la pastilla del mensaje: es lo unico de esa franja que
/// ocupa todo el ancho (la marca va centrada y no lo nota). A 8 la pastilla
/// mide 784 en el panel -- el 98% del ancho, 1.8 veces el lado del recuadro
/// QR. Por debajo de esto ya no es una pastilla, es una barra pegada al
/// borde del cristal.
const double _margenFranjaSuperior = 8.0;

/// Aire entre el bloque del asistente (etiqueta + mascota, arriba a la
/// derecha) y la pastilla del mensaje.
///
/// [KigoDesign.clearanceAsistenteArriba] sola deja la pastilla a 8px del
/// dibujo de la mascota: no se solapan, pero de lejos -- que es como se ve un
/// kiosko -- el borde de la pastilla parece parte del asistente. Esto los
/// separa lo justo para que se lean como dos cosas distintas sin que la
/// pastilla se despegue y quede flotando a media franja.
const double _huecoAsistentePastilla = 12.0;

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

  final LedServicio _led = LedServicio();

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
    _led.apagar();
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
    _led.encenderIluminacion();
    // Mismo momento en que arranca la cámara: el lector físico dedicado
    // (teclado-wedge) solo debe recibir foco mientras esta pantalla está
    // realmente activa y lista, igual que la cámara.
    _lectorFisicoFocus.requestFocus();
  }

  void _liberarCamara() {
    final viejo = _controller;
    if (viejo == null) return;
    _led.apagar();
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
    final recuadro = rectRecuadroQr(pantalla);
    final topRecuadro = recuadro.top;
    final bottomRecuadro = recuadro.bottom.clamp(0.0, pantalla.height);

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
                  // A veces la cámara no arranca (permiso revocado a medio
                  // uso, lente ocupada por otra vista que no soltó a
                  // tiempo) y sin esto el kiosko se quedaba con un cuadro
                  // negro sin ninguna pista de qué pasó -- el visitante no
                  // tiene forma de saber si es normal o está roto.
                  errorBuilder: (context, error, child) => Container(
                    color: context.kBg,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info_outline_rounded, color: context.kTextSecondary, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          AppLocalizations.t(context, 'no_se_pudo_activar_camara'),
                          style: TextStyle(color: context.kTextSecondary, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
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
              padding: EdgeInsets.fromLTRB(
                _margenFranjaSuperior,
                safe.top + 24,
                _margenFranjaSuperior,
                20,
              ),
              child: Column(
                children: [
                  // La marca y el bloque del asistente (etiqueta + mascota,
                  // pegado al techo a la derecha) comparten renglón, y el
                  // renglón lo dicta el más alto de los dos: el asistente.
                  // Sin esta reserva el badge de comunidad -- que es de ancho
                  // completo -- subía hasta meterse por debajo de la mascota
                  // (medido: su borde de arriba caía 10px dentro de ella).
                  // El tope contra la franja es para el apaisado, donde no
                  // hay 108px que reservar; ahí el FittedBox achica la marca
                  // en vez de desbordar.
                  SizedBox(
                    height: math.min(
                      KigoDesign.clearanceAsistenteArriba -
                          24 +
                          _huecoAsistentePastilla,
                      math.max(topRecuadro - safe.top - 44, 0.0) * 0.55,
                    ),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.topCenter,
                      child: KigoWordmark(escala: 1.7),
                    ),
                  ),
                  Expanded(
                    // Arriba, no centrada: así la pastilla queda lo más
                    // pegada posible al bloque del asistente (el renglón de
                    // arriba ya reservó su huella exacta) en vez de flotar a
                    // media altura entre él y el recuadro.
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: mensaje.isEmpty
                          ? const SizedBox.shrink()
                          : FittedBox(
                              fit: BoxFit.scaleDown,
                              child: SizedBox(
                                width: pantalla.width -
                                    _margenFranjaSuperior * 2,
                                // Sin `Center` en medio: con él la pastilla se
                                // encogía hasta abrazar su texto, así que su
                                // ancho lo decidía el mensaje del dashboard y
                                // no el hueco reservado -- subir la escala
                                // agrandaba la letra pero la pastilla seguía a
                                // media pantalla. Pegada al SizedBox recibe
                                // ancho fijo y ocupa la franja completa.
                                // 3.0 sale de medir el hueco: la franja de
                                // arriba deja 264px y a esta escala la
                                // pastilla ocupa 187 con dos renglones y 247
                                // con tres, así que entra sin que el
                                // FittedBox tenga que encogerla en ninguno de
                                // los dos casos. El alto de cada renglón sí
                                // es independiente de la fuente (se lo fija
                                // el `height: 1.25` del badge); cuántos
                                // renglones salen, no.
                                child: ComunidadBadge(
                                  mensaje: mensaje,
                                  escala: 3.0,
                                  envolverTexto: true,
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
              // El CTA se cuelga del piso, no del recuadro: queda exactamente
              // [_huecoCtaBotonesFlotantes] por encima del micrófono y el
              // vigilante, que ocupan 64 de lado a 20 del borde de abajo.
              // El tope contra la mitad de la franja es para el apaisado
              // bajito (784x361), donde la reserva entera dejaría al
              // FittedBox con alto negativo (RenderParagraph con NaN, ver
              // qr_scanner_layout_test.dart).
              padding: EdgeInsets.fromLTRB(
                25,
                12,
                25,
                math.min(
                  safe.bottom +
                      KigoDesign.offsetBotonesFlotantes +
                      KigoDesign.ladoBotonAccion +
                      _huecoCtaBotonesFlotantes,
                  (pantalla.height - bottomRecuadro) * 0.5,
                ),
              ),
              // El ancho pedido es exactamente el que deja el padding de 24
              // por lado. Antes pedía `width - 32`, 16px más de los que hay:
              // el FittedBox no tenía más remedio que encoger todo el bloque
              // aunque sobrara alto, así que el CTA nunca llegaba a ocupar la
              // franja completa.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                // Al piso de su franja: lo que sobra queda ARRIBA, entre el
                // recuadro y el texto, no repartido a la mitad.
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  width: pantalla.width - 50,
                  child: _buildBottomHint(
                    math.min(_anchoBotonPedido, pantalla.width - 50),
                  ),
                ),
              ),
            ),
          ),

          // Mismo padding top que el KigoWordmark de la franja de arriba
          // (24 + safe area) para que quede a su misma altura, a la derecha.
          BotonAsistenteFlotante(
            topDelBorde: 24,
            rightDelBorde: 24,
            mostrarEtiqueta: true,
            controlador: _asistenteController,
            onRespuestaLibre: (_) {},
            onCampoExtraido: (_) {},
          ),
        ],
      ),
    );
  }

  /// Tipografía de kiosko: esto se lee de pie y a un brazo de distancia, no
  /// con el teléfono en la mano.
  Widget _buildBottomHint(double ancho) {
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
              fontSize: 35,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.t(context, 'codigo_personal_o_invitacion'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.kTextSecondary,
            fontSize: 19,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 20),
        _buildBotonSinCodigo(ancho),
      ],
    );
  }

  /// Acción primaria de quien llega sin QR — mismo naranja y mismo resplandor
  /// que los botones de la pantalla de bienvenida.
  Widget _buildBotonSinCodigo(double ancho) {
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
        width: ancho,
        height: _altoBotonSinCodigo,
        alignment: Alignment.center,
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
        // Con el alto fijo el texto ya no puede empujar la caja, así que le
        // toca a él caber: el ancho interior (20 de margen por lado) es el
        // que decide dónde parte el renglón, y el FittedBox sólo entra en
        // acción si aun así no cabe -- en inglés la frase es más larga y se
        // va a tres renglones. Sin esta red, ahí desbordaría.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: ancho - 40,
            child: Text(
              AppLocalizations.t(context, 'no_tengo_app_o_qr'),
              textAlign: TextAlign.center,
              // 38 dejaba la frase en tres renglones: de un tirón pide
              // ~1400px, más del ancho entero del panel. A 32 parte limpio en
              // dos ("No tengo la app" / "AUTOnomIA o código QR") y sigue
              // siendo más grande que el subtítulo de la franja.
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
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

    // El hueco sale de rectRecuadroQr, el mismo que usa el layout para
    // colocar las franjas de texto: calcularlo aquí de nuevo es justo lo que
    // dejó el anillo montado encima del "Apunta al código QR".
    final hueco = rectRecuadroQr(size);
    // Respiración sutil (0.97–1.0) mientras espera; sólido y estable ya
    // detectado. Late alrededor de su propio centro, así que nunca se sale
    // del hueco reservado.
    final escala = scanned ? 1.0 : 0.97 + (0.03 * pulso);
    final rect = Rect.fromCenter(
      center: hueco.center,
      width: hueco.width * escala,
      height: hueco.height * escala,
    );
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
