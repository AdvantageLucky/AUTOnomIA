/* VISTA PRINCIPAL DE BIENVENIDA */
import 'dart:async';
import 'dart:math' as math;

import 'package:kigo_kiosco/features/registro/views/touch_register_view.dart';
import 'package:kigo_kiosco/features/welcome/views/operator_exit_pin_view.dart';
import 'package:kigo_kiosco/features/welcome/viewmodels/operator_exit_viewmodel.dart';
import 'package:kigo_kiosco/features/residente/views/residente_acceso_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kigo_kiosco/core/notifiers/kiosko_config_notifier.dart';
import 'package:kigo_kiosco/core/routing/registro_router.dart';
import 'package:kigo_kiosco/core/services/connectivity_service.dart';
import 'package:kigo_kiosco/core/theme/kigo_design.dart';
import 'package:kigo_kiosco/core/widgets/boton_asistente_flotante.dart';
import 'package:kigo_kiosco/core/widgets/marca_badge.dart';
import 'package:kigo_kiosco/core/widgets/pantalla_adaptable.dart';
import 'package:kigo_kiosco/core/widgets/presionable.dart';
import 'package:kigo_kiosco/features/welcome/viewmodels/welcome_viewmodel.dart';
import 'package:kigo_kiosco/features/welcome/views/widgets/comunidad_badge.dart';
import 'package:kigo_kiosco/l10n/app_localizations.dart';

/// El bloque de bienvenida (título, pastilla del mensaje y subtítulo) crece
/// 20px, medidos sobre el título -- que con `height: 1` mide exactamente su
/// fontSize, así que 52 -> 72 son 20 clavados.
///
/// Los otros dos crecen con ESE factor y no sumando 20 cada uno: al
/// subtítulo, que mide 11, sumarle 20 lo pondría en 31 -- más grande que
/// cualquier otra cosa del bloque menos el título, y dejaría de ser el
/// renglón fino entre dos líneas decorativas que es hoy. La pastilla lo
/// mismo. Un solo factor es lo que mantiene la forma del bloque: crece
/// entero, no se recompone.
const double _fuenteTituloBienvenida = 72;
const double _escalaBienvenida = _fuenteTituloBienvenida / 52;
const double _espaciadoTituloBienvenida = -1.5 * _escalaBienvenida;

/// La pastilla escala por su propio parámetro, que multiplica la pieza
/// completa (relleno, borde, punto y letra) -- es la misma que el escáner QR
/// usa a x3.
const double _escalaPastillaBienvenida = _escalaBienvenida;

/// El renglón fino de abajo: la letra, su tracking y las dos líneas
/// decorativas que lo enmarcan, todo al mismo factor para que siga leyéndose
/// como un solo elemento.
const double _fuenteSubtituloBienvenida = 11 * _escalaBienvenida;
const double _espaciadoSubtituloBienvenida = 2.5 * _escalaBienvenida;
const double _anchoLineaBienvenida = 28 * _escalaBienvenida;
const double _huecoLineaSubtitulo = 12 * _escalaBienvenida;

/// Los dos huecos de adentro del bloque (título -> pastilla -> subtítulo).
/// El aire que lo separa del orbe de arriba no se toca: el orbe no entra en
/// lo que se pidió agrandar.
const double _huecoTituloPastilla = 16 * _escalaBienvenida;
const double _huecoPastillaSubtitulo = 18 * _escalaBienvenida;

/// El header crece 10px: el botón de regresar de 44 a 54, el isotipo de 48 a
/// 58 y la mascota del asistente de 96 a 106. Se lee de pie y a un brazo de
/// distancia, y era la única fila de la pantalla que se había quedado con
/// medidas de teléfono.
///
/// Lo de adentro de cada pieza NO suma 10: sigue a la proporción de su caja.
/// Sumarle 10 a la flecha (18 -> 28) dentro de un botón que creció un 23% la
/// dejaría llenándolo de borde a borde, y 10 más al subtítulo (14 -> 24) lo
/// dejaría casi tan grande como el nombre. Se piden botones más grandes, no
/// una composición distinta.
const double _ladoBotonRegresar = 54;
const double _escalaBotonRegresar = _ladoBotonRegresar / 44;
const double _tamanoFlechaRegresar = 18 * _escalaBotonRegresar;
const double _radioBotonRegresar = KigoDesign.radius * _escalaBotonRegresar;

/// El isotipo, el nombre y el subtítulo son una sola pieza y crecen con un
/// solo factor -- el del isotipo, que es lo único de los tres que tiene una
/// medida en px que se pueda subir 10. Con factores distintos el nombre se
/// despegaría del logo y dejaría de leerse como un lockup.
const double _ladoLogoHeader = 58;
const double _escalaLockup = _ladoLogoHeader / 48;
const double _huecoLogoNombre = 14 * _escalaLockup;
const double _fuenteNombreHeader = 29 * _escalaLockup;
const double _fuenteSubtituloHeader = 14 * _escalaLockup;
const double _huecoNombreSubtitulo = 2 * _escalaLockup;
const double _espaciadoSubtituloHeader = 4 * _escalaLockup;

/// La mascota de esta pantalla, 10 más que la de las demás
/// ([KigoDesign.ladoAsistente]). Se pasa por parámetro y no se sube en la
/// constante para no descuadrar a las otras cuatro pantallas que se anclan a
/// ella.
const double _ladoAsistenteHeader = KigoDesign.ladoAsistente + 10;

/// Padding horizontal de la pantalla. Lo comparten PantallaAdaptable y el
/// `rightDelBorde` de la mascota, que es lo que hace que la mascota arranque
/// justo en el borde derecho de la fila del header.
const double _margenHorizontal = 34;

/// Aire mínimo entre el lockup de marca y la mascota que flota a su derecha.
const double _aireLockupMascota = 12;

/// Alto de los dos botones de opción ("residente" / "visitante").
///
/// Es la única medida que se elige: el ancho lo reparte el `Row` a medias
/// entre los dos y no hay número que ponerle. Eran 160; los 210 se piden para
/// que el par de botones pese en la pantalla lo mismo que el bloque de
/// bienvenida que tienen encima -- el kiosko se opera de pie y a un brazo de
/// distancia, y es la fila donde el visitante decide.
const double _altoBotonOpcion = 210;

/// El contenido del botón crece con la caja, en la misma proporción con la
/// que se compuso a 160: si no, subir el alto sólo abre aire alrededor de un
/// icono y una etiqueta que se quedan chicos y el botón se lee vacío. Se
/// escriben como esa proporción y no como números sueltos para que la
/// siguiente vez que cambie el alto arrastre a los tres.
const double _tamanoIconoBotonOpcion = _altoBotonOpcion * 72 / 160;
const double _fuenteBotonOpcion = _altoBotonOpcion * 18 / 160;
const double _huecoIconoTextoBotonOpcion = _altoBotonOpcion * 14 / 160;

class WelcomeView extends StatefulWidget {
  final WelcomeViewModel viewModel;

  const WelcomeView({
    super.key,
    required this.viewModel,
  });

  @override
  State<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<WelcomeView>
    with TickerProviderStateMixin {
  String? _presionadoId;
  Timer? _salidaOperadorTimer;

  late final AnimationController _entradaCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_updateView);

    _entradaCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _entradaCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entradaCtrl, curve: Curves.easeOutCubic));

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.72, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _entradaCtrl.forward();
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_updateView);
    _salidaOperadorTimer?.cancel();
    _entradaCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _updateView() => setState(() {});

  // Mantener presionada la pantalla de bienvenida 5s abre el PIN de
  // operador para salir del modo kiosko; un toque normal nunca llega a los 5s.
  void _iniciarConteoSalidaOperador() {
    _salidaOperadorTimer?.cancel();
    _salidaOperadorTimer = Timer(const Duration(seconds: 5), _abrirSalidaOperador);
  }

  void _cancelarConteoSalidaOperador() {
    _salidaOperadorTimer?.cancel();
    _salidaOperadorTimer = null;
  }

  void _abrirSalidaOperador() {
    _salidaOperadorTimer = null;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => OperatorExitPinView(viewModel: OperatorExitViewModel()),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cfg = context.watch<KioskoConfigNotifier>().config;
    final mensaje = cfg.mensajeBienvenida.trim();

    return Stack(
      children: [
        Scaffold(
          body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => _iniciarConteoSalidaOperador(),
            onTapUp: (_) => _cancelarConteoSalidaOperador(),
            onTapCancel: _cancelarConteoSalidaOperador,
            child: PantallaAdaptable(
              // El footer, empujado al fondo por el segundo Spacer, quedaba
              // pegado (a veces detrás) del micrófono/vigilante de
              // BotonAsistenteFlotante -- confirmado por screenshot.
              padding: const EdgeInsets.fromLTRB(34, 48, 34, 48 + KigoDesign.clearanceBotonesFlotantes),
              child: Column(
                children: [
                  _buildHeader(context),
                  const Spacer(),
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: _buildWelcomeSection(mensaje),
                    ),
                  ),
                  const SizedBox(height: 56),
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: _buildBotones(context),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
        BotonAsistenteFlotante(
          // Coincide con el padding vertical/horizontal de PantallaAdaptable
          // en esta pantalla (48/34) para alinear con la fila de header real.
          topDelBorde: 48,
          rightDelBorde: 34,
          lado: _ladoAsistenteHeader,
          onRespuestaLibre: (_) {}, // la respuesta ya se leyó por TTS dentro de AsistenteServicio
          onCampoExtraido: (_) {}, // WelcomeView no llena campos — tipoCampo queda null
        ),
      ],
    );
  }

  Widget _buildWelcomeSection(String mensaje) {
    return Column(
      children: [
        // Orbe decorativo animado
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, child) => Transform.scale(
            scale: _pulseAnim.value,
            child: Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    KigoDesign.brand.withValues(alpha: 0.30),
                    KigoDesign.brand.withValues(alpha: 0.0),
                  ],
                ),
              ),
              child: Center(
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: KigoDesign.brand.withValues(alpha: 0.22),
                    border: Border.all(
                      color: KigoDesign.brand.withValues(alpha: 0.65),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.waving_hand_rounded,
                    color: KigoDesign.brand,
                    size: 26,
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Título principal
        // Los dos FittedBox son la red del bloque en pantallas angostas. A 52
        // el título cabía de largo casi en cualquier lienzo; a 72 mide 374 y
        // en un teléfono de 411 (343 útiles) Flutter partía la palabra a la
        // mitad -- "Bienveni/do". La pastilla, por su lado, recortaba el
        // mensaje con puntos suspensivos. Encogidos enteros los dos siguen
        // siendo lo mismo, más chico; partidos o recortados, no.
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            AppLocalizations.t(context, 'bienvenido_title'),
            maxLines: 1,
            style: TextStyle(
              color: context.kTextPrimary,
              fontSize: _fuenteTituloBienvenida,
              fontWeight: FontWeight.w900,
              letterSpacing: _espaciadoTituloBienvenida,
              height: 1,
            ),
          ),
        ),

        // Nombre de la comunidad desde la config
        if (mensaje.isNotEmpty) ...[
          const SizedBox(height: _huecoTituloPastilla),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: ComunidadBadge(
                mensaje: mensaje, escala: _escalaPastillaBienvenida),
          ),
        ],

        const SizedBox(height: _huecoPastillaSubtitulo),

        // Línea decorativa y subtítulo
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLinea(),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: _huecoLineaSubtitulo),
                child: Text(
                  AppLocalizations.t(context, 'selecciona_como_continuar'),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.kTextTertiary,
                    fontSize: _fuenteSubtituloBienvenida,
                    fontWeight: FontWeight.w600,
                    letterSpacing: _espaciadoSubtituloBienvenida,
                  ),
                ),
              ),
            ),
            _buildLinea(),
          ],
        ),
      ],
    );
  }

  Widget _buildLinea() => Container(
        width: _anchoLineaBienvenida,
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            Colors.transparent,
            context.kTextTertiary.withValues(alpha: 0.5),
          ]),
        ),
      );

  Widget _buildBotones(BuildContext context) {
    final options = widget.viewModel.options;
    // El registro de visitante sin invitación (INE + rostro) necesita
    // backend en vivo: valida contra el catálogo de residentes/invitaciones
    // del tenant y decide autopase con datos que no existen en el caché
    // offline. A diferencia del QR (que sí puede validar contra la cola
    // local), aquí no hay nada sensato que hacer sin red -- mejor
    // deshabilitar el botón que dejar que el visitante llene todo el flujo
    // para enterarse hasta el final que no se pudo registrar.
    final offline = context.watch<ConnectivityService>().isOffline;
    return Row(
      children: [
        Expanded(
            child: _buildBoton(context, options[0].id, options[0].icon,
                AppLocalizations.t(context, options[0].titleKey))),
        const SizedBox(width: 20),
        Expanded(
            child: _buildBoton(
          context,
          options[1].id,
          options[1].icon,
          AppLocalizations.t(context, options[1].titleKey),
          deshabilitado: options[1].id == 'visitante' && offline,
        )),
      ],
    );
  }

  Widget _buildBoton(
      BuildContext context, String id, IconData icono, String label,
      {bool deshabilitado = false}) {
    const orange = KigoDesign.brand;
    const orangeLight = KigoDesign.brandHover;
    final gray = context.kSurface2;

    final bool presionado = !deshabilitado && _presionadoId == id;

    return GestureDetector(
      onTapDown: deshabilitado
          ? null
          : (_) => setState(() => _presionadoId = id),
      onTapUp: deshabilitado
          ? null
          : (_) {
              setState(() => _presionadoId = null);
              widget.viewModel.selectOption(id);
              final navigator = Navigator.of(context);
              final config = context.read<KioskoConfigNotifier>().config;
              Future.delayed(const Duration(milliseconds: 160), () {
                if (id == 'visitante') {
                  // El QR ya se ofrece en la pantalla principal del kiosko — llegar
                  // aquí significa que la visita no trae ninguno, así que se salta
                  // directo al registro sin invitación.
                  navigator.push(MaterialPageRoute(
                    builder: (_) => RegistroRouter.paraVisitante(config),
                  ));
                } else if (id == 'residente') {
                  navigator.push(MaterialPageRoute(
                    builder: (_) => const ResidenteAccesoView(),
                  ));
                } else {
                  navigator.push(MaterialPageRoute(
                      builder: (_) => const TouchRegisterView()));
                }
              });
            },
      onTapCancel: deshabilitado
          ? null
          : () => setState(() => _presionadoId = null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        height: _altoBotonOpcion,
        decoration: BoxDecoration(
          color: deshabilitado
              ? context.kSurface2.withValues(alpha: 0.5)
              : (presionado ? orangeLight : gray),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: deshabilitado
                ? context.kBorder
                : (presionado ? orangeLight : orange.withValues(alpha: 0.25)),
            width: 1.5,
          ),
          boxShadow: presionado
              ? [
                  BoxShadow(
                    color: orange.withValues(alpha: 0.35),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        // La red de seguridad del contenido: el icono y la etiqueta están
        // dimensionados para el panel, donde cada botón mide 356 de ancho, y
        // en un teléfono de 320 le tocan 113. Sin esto la etiqueta se partía
        // en tres renglones y el Column desbordaba por 7.9px (confirmado con
        // pantallas_adaptables_test en 320x640); con esto el par
        // icono+etiqueta se encoge junto, que es como se compuso.
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icono,
                  color: deshabilitado
                      ? context.kTextTertiary
                      : (presionado ? Colors.white : orange),
                  size: _tamanoIconoBotonOpcion,
                ),
                const SizedBox(height: _huecoIconoTextoBotonOpcion),
                Text(
                  label,
                  style: TextStyle(
                    color: deshabilitado
                        ? context.kTextTertiary
                        : (presionado ? Colors.white : context.kTextPrimary),
                    fontSize: _fuenteBotonOpcion,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    // Lo más ancho que puede ser el lockup sin meterse debajo de la mascota.
    //
    // El lockup va centrado en la pantalla (los dos extremos de la fila miden
    // lo mismo) y la mascota flota pegada al borde derecho, fuera de esta
    // fila: la mitad derecha del lockup sólo tiene libre lo que hay entre el
    // centro de la pantalla y el borde izquierdo del dibujo. En el panel eso
    // da 496 para un lockup que mide 258 y no pasa nada; en un teléfono
    // angosto es lo que evita que el nombre termine pintado debajo de la
    // mascota -- pasaba ya antes de agrandar el header (medido: -10px de
    // solape en 320x640) y crecer las dos piezas lo habría llevado a -20.
    final ancho = MediaQuery.sizeOf(context).width;
    final bordeIzquierdoMascota =
        ancho - _margenHorizontal - _ladoAsistenteHeader;
    final anchoMaxLockup = math.max(
      (bordeIzquierdoMascota - ancho / 2 - _aireLockupMascota) * 2,
      0.0,
    );
    return Row(
      children: [
        Presionable(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: _ladoBotonRegresar,
            height: _ladoBotonRegresar,
            decoration: BoxDecoration(
              color: KigoDesign.brand,
              borderRadius: BorderRadius.circular(_radioBotonRegresar),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: _tamanoFlechaRegresar,
            ),
          ),
        ),
        // Un `Expanded` con `Center` y no dos `Spacer` con el lockup en
        // medio: los `Spacer` son flex igual que él, así que le repartían un
        // tercio del sobrante y el `FittedBox` encogía el lockup para caber
        // en ese tercio aunque la fila entera tuviera sitio de sobra (en el
        // panel lo dejaba al 81%). Con esto sólo encoge cuando de verdad no
        // cabe, y sigue centrado en pantalla porque los dos extremos de la
        // fila miden lo mismo.
        Expanded(
          child: Center(
        // Isotipo + nombre + subtítulo son una sola pieza y encogen juntos.
        // El logo estaba fuera del FittedBox, con medida fija: en una
        // pantalla angosta el texto se achicaba hasta ser ilegible mientras
        // el logo seguía enorme al lado -- que es justo "desarmarse". Dentro,
        // el lockup mantiene su proporción a cualquier ancho.
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: anchoMaxLockup),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const MarcaBadge(lado: _ladoLogoHeader),
                    const SizedBox(width: _huecoLogoNombre),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppLocalizations.t(context, 'kigo_label'),
                            style: TextStyle(
                                color: context.kTextPrimary,
                                fontSize: _fuenteNombreHeader,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: _huecoNombreSubtitulo),
                        Text(AppLocalizations.t(context, 'self_checkin_label'),
                            style: TextStyle(
                                color: context.kTextSecondary,
                                fontSize: _fuenteSubtituloHeader,
                                letterSpacing: _espaciadoSubtituloHeader,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // El botón del asistente ya no vive aquí -- flota sobre toda la
        // pantalla vía BotonAsistenteFlotante (mismo lugar en las 3
        // pantallas que lo usan). Este espacio se conserva para que el
        // bloque de logo + nombre siga centrado igual que antes, así que
        // mide lo mismo que el botón de regresar del otro extremo.
        const SizedBox(width: _ladoBotonRegresar),
      ],
    );
  }

}
