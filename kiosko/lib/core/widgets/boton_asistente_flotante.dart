import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kigo_kiosco/core/models/campo_extraido.dart';
import 'package:kigo_kiosco/core/notifiers/kiosko_config_notifier.dart';
import 'package:kigo_kiosco/core/services/asistente_controller.dart';
import 'package:kigo_kiosco/core/services/asistente_servicio.dart';
import 'package:kigo_kiosco/core/services/connectivity_service.dart';
import 'package:kigo_kiosco/core/services/led_servicio.dart';
import 'package:kigo_kiosco/core/theme/kigo_design.dart';
import 'package:kigo_kiosco/core/widgets/asistencia_urgente_sheet.dart';
import 'package:kigo_kiosco/core/widgets/etiqueta_asistente.dart';
import 'package:kigo_kiosco/core/widgets/faq_offline_sheet.dart';
import 'package:kigo_kiosco/core/widgets/mascota_asistente.dart';
import 'package:kigo_kiosco/core/widgets/menu_ayuda_sheet.dart';
import 'package:kigo_kiosco/core/widgets/presionable.dart';
import 'package:kigo_kiosco/features/registro/services/kiosko_servicio.dart';
import 'package:kigo_kiosco/features/registro/services/text_to_speak_servicio.dart';

enum _EstadoAsistente { inactivo, escuchando, procesando, hablando }

/// Lado de los botones de acción (micrófono, vigilante) — deliberadamente
/// más chico que la mascota (`KigoDesign.ladoAsistente`): son controles de
/// esquina, no el protagonista visual de la pantalla.
const double _ladoBotonAccion = 64;

/// Posiciona la mascota (arriba a la derecha, alineada con el header propio
/// de cada pantalla) y los dos botones de acción -- micrófono y vigilante
/// (abajo a la derecha, siempre accesibles) -- como hijo directo de un
/// `Stack` que cubra la pantalla.
///
/// Antes un solo botón (la mascota) hacía de todo: mantener presionado para
/// hablar, tocar para llamar al administrador. Eso obligaba a tapar la
/// mascota con el dedo para usar cualquiera de las dos funciones, y
/// escondía "llamar al vigilante" detrás de un tap que nadie adivinaba. Se
/// dividió: la mascota ahora es solo el indicador visual del asistente
/// (habla -- narra las respuestas), y dos botones nuevos, abajo a la
/// derecha, concentran la interacción real: el micrófono para hablar y el
/// de ayuda para llamar al vigilante o ver las preguntas frecuentes.
///
/// [topDelBorde] es el offset vertical (respecto al borde superior de
/// pantalla, sin contar el safe area, que se suma aparte) del header de esa
/// pantalla en particular -- no hay un único valor correcto para las tres,
/// cada una define su propio padding/estructura de header. Pásalo igual al
/// padding/inset real que usa esa pantalla para su fila de arriba.
///
/// [rightDelBorde] es el equivalente horizontal para ambos grupos (mascota
/// arriba, botones abajo) -- antes estaba fijo en 12, lo que dejaba el
/// ícono 16-22px más cerca del borde físico de lo que le correspondía en
/// pantallas con más padding horizontal.
///
/// [bottomDelBorde] es el offset vertical de los botones de acción respecto
/// al borde inferior (sin contar el safe area). Si el contenido propio de la
/// pantalla ya ocupa esa esquina, hay que subirlo -- ver comentario en cada
/// pantalla que lo necesitó.
///
/// [mostrarEtiqueta] pone "Asistente IA" DEBAJO de la mascota (no al lado):
/// como la mascota ya no compite por espacio con nada más a su derecha, no
/// hay razón para apretarla a un costado.
class BotonAsistenteFlotante extends StatefulWidget {
  final String? tipoCampo;
  final void Function(String respuesta) onRespuestaLibre;
  final void Function(CampoExtraido) onCampoExtraido;
  final double topDelBorde;
  final double rightDelBorde;
  final double bottomDelBorde;
  final AsistenteController? controlador;
  final bool mostrarEtiqueta;

  const BotonAsistenteFlotante({
    super.key,
    this.tipoCampo,
    required this.onRespuestaLibre,
    required this.onCampoExtraido,
    required this.topDelBorde,
    this.rightDelBorde = 12,
    this.bottomDelBorde = 20,
    this.controlador,
    this.mostrarEtiqueta = false,
  });

  @override
  State<BotonAsistenteFlotante> createState() => _BotonAsistenteFlotanteState();
}

class _BotonAsistenteFlotanteState extends State<BotonAsistenteFlotante> with TickerProviderStateMixin {
  final AsistenteServicio _asistente = AsistenteServicio();
  final KioskoServicio _kiosko = KioskoServicio();
  final TextToSpeakServicio _tts = TextToSpeakServicio();
  final LedServicio _led = LedServicio();
  _EstadoAsistente _estado = _EstadoAsistente.inactivo;
  bool _micDisponible = true;

  // Ambar en el LED mientras no hay internet -- señal ambiental que un
  // vigilante nota de reojo sin que un visitante entienda qué significa.
  // Este widget vive en (casi) toda pantalla, así que es el punto natural
  // para reaccionar a la conectividad sin duplicar la suscripción en cada
  // vista. `addListener` (no context.watch en build) para no reprender el
  // canal nativo en cada rebuild, solo en transiciones reales.
  ConnectivityService? _connectivity;
  bool? _ultimoOffline;

  /// El dedo tapa el boton mientras lo mantiene presionado, asi que el
  /// unico feedback util es el que se nota en el borde: encoge un poco y
  /// enciende el halo. Sin esto no habia forma de saber si registro el
  /// toque -- el long-press no cambiaba nada visible hasta empezar a oir.
  bool _presionado = false;

  /// La cabeza de la mascota "respira" (rebota, parpadea la boca) mientras
  /// escucha o habla.
  late final AnimationController _pulseCtrl;

  /// Los puntitos de "procesando" bajo la cabeza avanzan en cascada.
  late final AnimationController _rotCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _rotCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
    _asistente.iniciar().then((ok) {
      if (mounted) setState(() => _micDisponible = ok);
    }).catchError((e) {
      // Sin servicio de voz del sistema instalado (o un fallo del plugin),
      // el botón de micrófono se deshabilita como si el permiso no
      // estuviera dado -- sin este catch, la excepción quedaba sin manejar.
      debugPrint('No se pudo iniciar el reconocimiento de voz: $e');
      if (mounted) setState(() => _micDisponible = false);
    });
    widget.controlador?.addListener(_onControladorDecir);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _connectivity = context.read<ConnectivityService>();
      _connectivity!.addListener(_onConnectivityChanged);
      _onConnectivityChanged();
    });
  }

  void _onConnectivityChanged() {
    final offline = _connectivity?.isOffline ?? false;
    if (_ultimoOffline == offline) return;
    _ultimoOffline = offline;
    if (offline) {
      _led.mostrarOffline();
    } else {
      _led.apagar();
    }
  }

  @override
  void didUpdateWidget(covariant BotonAsistenteFlotante oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controlador != widget.controlador) {
      oldWidget.controlador?.removeListener(_onControladorDecir);
      widget.controlador?.addListener(_onControladorDecir);
    }
  }

  @override
  void dispose() {
    widget.controlador?.removeListener(_onControladorDecir);
    _connectivity?.removeListener(_onConnectivityChanged);
    _asistente.dispose();
    _pulseCtrl.dispose();
    _rotCtrl.dispose();
    super.dispose();
  }

  /// El controlador pidió narrar algo -- se ignora si el usuario ya está
  /// interactuando (escuchando/procesando), para no interrumpirlo con una
  /// narración automática a mitad de su propia pregunta.
  Future<void> _onControladorDecir() async {
    final texto = widget.controlador?.textoPendiente;
    if (texto == null) return;
    if (_estado != _EstadoAsistente.inactivo) return;

    setState(() => _estado = _EstadoAsistente.hablando);
    try {
      await _tts.speak(texto);
    } catch (e) {
      debugPrint('Error narrando: $e');
    } finally {
      if (mounted && _estado == _EstadoAsistente.hablando) {
        setState(() => _estado = _EstadoAsistente.inactivo);
      }
    }
  }

  Future<void> _onPressStart() async {
    if (!_micDisponible) return;
    if (_estado == _EstadoAsistente.hablando) {
      // Barge-in: el usuario empezó a hablar mientras ella narraba -- se
      // corta la narración en curso, no hay que esperar a que termine.
      await _tts.stop();
    }
    setState(() => _estado = _EstadoAsistente.escuchando);

    try {
      await _asistente
          .escuchar(
            tipoCampo: widget.tipoCampo,
            onRespuestaLibre: (respuesta) {
              if (mounted) setState(() => _estado = _EstadoAsistente.inactivo);
              widget.onRespuestaLibre(respuesta);
            },
            onCampoExtraido: (campo) {
              if (mounted) setState(() => _estado = _EstadoAsistente.inactivo);
              widget.onCampoExtraido(campo);
            },
            onNoEntendido: () {
              if (mounted) setState(() => _estado = _EstadoAsistente.inactivo);
            },
          )
          // Red de seguridad final: `AsistenteServicio.escuchar` ya tiene su
          // propio timeout interno, pero si algo fuera de ese alcance se
          // cuelga (ej. `_ensureLogin` leyendo secure storage), el ícono no
          // debe quedar en "procesando" para siempre.
          .timeout(const Duration(seconds: 20));
    } catch (e) {
      debugPrint('Error en asistente: $e');
    } finally {
      if (mounted && _estado != _EstadoAsistente.inactivo) {
        setState(() => _estado = _EstadoAsistente.inactivo);
      }
    }
  }

  /// Al soltar el botón: si seguía escuchando, corta ahí mismo (no espera
  /// los 15s de límite de seguridad) y pasa a "procesando" mientras el
  /// backend responde — el propio `escuchar()` de _onPressStart es quien
  /// vuelve a "inactivo" cuando el resultado llega.
  void _onPressEnd() {
    if (_estado != _EstadoAsistente.escuchando) return;
    setState(() => _estado = _EstadoAsistente.procesando);
    _asistente.detener();
  }

  @override
  Widget build(BuildContext context) {
    final offline = context.watch<ConnectivityService>().isOffline;
    // El teléfono viaja en la config cacheada localmente -- por eso el botón
    // de ayuda funciona incluso sin conexión del kiosko: no hace falta
    // pedirle nada al backend, y quien llama es el celular del visitante
    // (red móvil), no el wifi del kiosko.
    final telefonoContacto = context.watch<KioskoConfigNotifier>().config.telefonoContacto;
    final safe = MediaQuery.paddingOf(context);

    return Positioned.fill(
      child: Stack(
        children: [
          // Mascota + etiqueta: solo indica estado (inactiva/escuchando/
          // procesando/hablando), no responde a toques -- la interacción
          // real vive en los dos botones de abajo.
          Positioned(
            top: widget.topDelBorde + safe.top,
            right: widget.rightDelBorde,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildMascotaConHalo(),
                if (widget.mostrarEtiqueta) ...[
                  const SizedBox(height: 6),
                  const EtiquetaAsistente(),
                ],
              ],
            ),
          ),

          // Micrófono (hablar) + vigilante (ayuda) -- siempre abajo a la
          // derecha, para que estén al alcance del pulgar sin taparse entre
          // sí ni con la mascota.
          Positioned(
            bottom: widget.bottomDelBorde + safe.bottom,
            right: widget.rightDelBorde,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Vigilante al final (más cerca de la esquina inferior
                // derecha real) -- es el botón de emergencia/ayuda, le
                // corresponde el lugar más a la mano, no el micrófono.
                _buildBotonMicrofono(offline, telefonoContacto),
                const SizedBox(width: 14),
                _buildBotonVigilante(telefonoContacto, offline),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Anillo que respira por FUERA de la mascota. Es lo unico que sigue
  /// siendo visible con la yema encima: el centro queda tapado, el borde no.
  Widget _buildHalo() {
    final activo = _estado == _EstadoAsistente.escuchando || _estado == _EstadoAsistente.procesando;
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, _) {
        final crecimiento = _estado == _EstadoAsistente.escuchando ? _pulseCtrl.value : 0.0;
        return AnimatedOpacity(
          opacity: activo ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 150),
          child: Container(
            width: KigoDesign.ladoAsistente * (0.9 + 0.1 * crecimiento),
            height: KigoDesign.ladoAsistente * (0.9 + 0.1 * crecimiento),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: KigoDesign.brand.withValues(alpha: 0.45),
                width: 3,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMascota() {
    final estadoMascota = switch (_estado) {
      _EstadoAsistente.inactivo => EstadoMascota.inactivo,
      _EstadoAsistente.escuchando => EstadoMascota.escuchando,
      _EstadoAsistente.procesando => EstadoMascota.procesando,
      _EstadoAsistente.hablando => EstadoMascota.hablando,
    };
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseCtrl, _rotCtrl]),
      builder: (context, _) => MascotaAsistente(
        estado: estadoMascota,
        pulseValue: _pulseCtrl.value,
        rotValue: _rotCtrl.value,
        lado: KigoDesign.ladoAsistente * 0.84,
      ),
    );
  }

  Widget _buildMascotaConHalo() {
    return SizedBox(
      width: KigoDesign.ladoAsistente,
      height: KigoDesign.ladoAsistente,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _buildHalo(),
          _buildMascota(),
        ],
      ),
    );
  }

  Widget _buildBotonVigilante(String telefonoContacto, bool offline) {
    return Tooltip(
      message: 'Ayuda: llamar al vigilante',
      child: Presionable(
        onTap: () => mostrarAsistenciaUrgente(
          context,
          telefonoContacto: telefonoContacto,
          offline: offline,
          onSolicitar: () => _kiosko.solicitarAsistenciaUrgente(),
        ),
        child: Container(
          width: _ladoBotonAccion,
          height: _ladoBotonAccion,
          decoration: BoxDecoration(
            color: context.kSurfaceCard,
            shape: BoxShape.circle,
            border: Border.all(color: context.kBorder, width: 1.5),
          ),
          child: Icon(Icons.support_agent_rounded, color: context.kTextPrimary, size: 30),
        ),
      ),
    );
  }

  Widget _buildBotonMicrofono(bool offline, String telefonoContacto) {
    // Sin red, el llenado de campos (placa/destino) no tiene alternativa —
    // necesita el LLM sí o sí. La pregunta libre (tipoCampo null) sí tiene
    // un modo sin conexión: tocar abre el mismo menú de ayuda (con FAQ), en
    // vez de escuchar.
    final requiereLlmSinAlternativa = offline && widget.tipoCampo != null;

    if (requiereLlmSinAlternativa) {
      return Tooltip(
        message: 'Sin conexión — usa el teclado/selector manual',
        child: Container(
          width: _ladoBotonAccion,
          height: _ladoBotonAccion,
          decoration: BoxDecoration(
            color: KigoDesign.brand.withValues(alpha: 0.35),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.mic_off_rounded, color: Colors.white, size: 28),
        ),
      );
    }

    final escuchando = _estado == _EstadoAsistente.escuchando;

    return Tooltip(
      message: !_micDisponible
          ? 'Activa el permiso de micrófono para usar el asistente'
          : offline
              ? 'Sin conexión — toca para ver ayuda'
              : 'Mantén presionado para hablar',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _presionado = true),
        onTapUp: (_) => setState(() => _presionado = false),
        onTapCancel: () => setState(() => _presionado = false),
        onTap: offline
            ? () => mostrarMenuAyuda(context, telefonoContacto: telefonoContacto, onFaq: () => mostrarFaqOffline(context))
            : null,
        onLongPressStart: offline
            ? null
            : (_) {
                setState(() => _presionado = true);
                _onPressStart();
              },
        onLongPressEnd: offline
            ? null
            : (_) {
                setState(() => _presionado = false);
                _onPressEnd();
              },
        child: AnimatedScale(
          scale: _presionado ? 0.9 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          child: Opacity(
            opacity: _micDisponible ? 1.0 : 0.4,
            child: Container(
              width: _ladoBotonAccion,
              height: _ladoBotonAccion,
              decoration: BoxDecoration(
                color: escuchando ? KigoDesign.brandHover : KigoDesign.brand,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: KigoDesign.brand.withValues(alpha: 0.4),
                    blurRadius: escuchando ? 22 : 14,
                    spreadRadius: escuchando ? 2 : 0,
                  ),
                ],
              ),
              child: Icon(
                escuchando ? Icons.mic_rounded : Icons.mic_none_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
