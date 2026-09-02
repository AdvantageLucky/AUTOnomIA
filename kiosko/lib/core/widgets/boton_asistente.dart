import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kigo_kiosco/core/models/campo_extraido.dart';
import 'package:kigo_kiosco/core/notifiers/kiosko_config_notifier.dart';
import 'package:kigo_kiosco/core/services/asistente_controller.dart';
import 'package:kigo_kiosco/core/services/asistente_servicio.dart';
import 'package:kigo_kiosco/core/services/connectivity_service.dart';
import 'package:kigo_kiosco/core/services/led_servicio.dart';
import 'package:kigo_kiosco/core/theme/kigo_design.dart';
import 'package:kigo_kiosco/core/widgets/faq_offline_sheet.dart';
import 'package:kigo_kiosco/core/widgets/mascota_asistente.dart';
import 'package:kigo_kiosco/core/widgets/menu_ayuda_sheet.dart';
import 'package:kigo_kiosco/core/widgets/presionable.dart';
import 'package:kigo_kiosco/features/registro/services/text_to_speak_servicio.dart';

enum _EstadoAsistente { inactivo, escuchando, procesando, hablando }

/// Los iconos de los dos modos sin conexion, proporcionales al lado del
/// boton (conservan la razon 20/44 del tamano original).
const double _ladoIcono = KigoDesign.ladoAsistente * 20 / 44;

/// Botón push-to-talk compartido: mantener presionado para hablar, soltar
/// para enviar. [tipoCampo] null => pregunta libre (WelcomeView, respondida
/// por voz). [tipoCampo] 'placa'|'destino' => extracción de campo (pantallas
/// de confirmación del flujo vehicular, silenciosa).
class BotonAsistente extends StatefulWidget {
  final String? tipoCampo;
  final void Function(String respuesta) onRespuestaLibre;
  final void Function(CampoExtraido) onCampoExtraido;
  final AsistenteController? controlador;

  const BotonAsistente({
    super.key,
    this.tipoCampo,
    required this.onRespuestaLibre,
    required this.onCampoExtraido,
    this.controlador,
  });

  @override
  State<BotonAsistente> createState() => _BotonAsistenteState();
}

class _BotonAsistenteState extends State<BotonAsistente> with TickerProviderStateMixin {
  final AsistenteServicio _asistente = AsistenteServicio();
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

  /// Punto de la antena de la mascota "respira" mientras escucha.
  late final AnimationController _pulseCtrl;

  /// Arco de la mascota gira alrededor del orbe mientras procesa.
  late final AnimationController _rotCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _rotCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
    _asistente.iniciar().then((ok) {
      if (mounted) setState(() => _micDisponible = ok);
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
  void didUpdateWidget(covariant BotonAsistente oldWidget) {
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
    // "llamar al administrador" funciona incluso sin conexión del kiosko: no
    // hace falta pedirle nada al backend, y quien llama es el celular del
    // visitante (red móvil), no el wifi del kiosko.
    final telefonoContacto = context.watch<KioskoConfigNotifier>().config.telefonoContacto;

    // Sin red, el llenado de campos (placa/destino) no tiene alternativa —
    // necesita el LLM sí o sí. La pregunta libre (tipoCampo null) sí tiene
    // un modo sin conexión: el FAQ fijo, en vez de escuchar.
    if (offline && widget.tipoCampo != null) {
      return Tooltip(
        message: 'Sin conexión — usa el teclado/selector manual',
        child: Presionable(
          onTap: () => mostrarMenuAyuda(context, telefonoContacto: telefonoContacto),
          child: Container(
            width: KigoDesign.ladoAsistente,
            height: KigoDesign.ladoAsistente,
            decoration: BoxDecoration(
              color: KigoDesign.brand.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(KigoDesign.radiusLg),
            ),
            child: const Icon(Icons.mic_off_rounded, color: Colors.white, size: _ladoIcono),
          ),
        ),
      );
    }

    if (offline) {
      return Tooltip(
        message: 'Sin conexión — toca para ver ayuda',
        child: Presionable(
          onTap: () => mostrarMenuAyuda(
            context,
            telefonoContacto: telefonoContacto,
            onFaq: () => mostrarFaqOffline(context),
          ),
          child: Container(
            width: KigoDesign.ladoAsistente,
            height: KigoDesign.ladoAsistente,
            decoration: BoxDecoration(
              color: KigoDesign.brand,
              borderRadius: BorderRadius.circular(KigoDesign.radiusLg),
            ),
            child: const Icon(Icons.help_outline_rounded, color: Colors.white, size: _ladoIcono),
          ),
        ),
      );
    }

    final sufijoAyuda = telefonoContacto.trim().isEmpty ? '' : ' · toca para llamar al administrador';
    return Tooltip(
      message: _micDisponible
          ? 'Mantén presionado para hablar$sufijoAyuda'
          : 'Activa el permiso de micrófono para usar el asistente',
      child: GestureDetector(
        // onTapDown/onTapCancel solo pintan el estado presionado: la acción
        // principal sigue siendo long-press (hablar). Un tap corto abre el
        // menú de ayuda (llamar al administrador) -- solo si hay teléfono
        // configurado, para no mostrar un menú vacío en kioskos sin uno.
        onTapDown: (_) => setState(() => _presionado = true),
        onTapUp: (_) => setState(() => _presionado = false),
        onTapCancel: () => setState(() => _presionado = false),
        onTap: telefonoContacto.trim().isEmpty
            ? null
            : () => mostrarMenuAyuda(context, telefonoContacto: telefonoContacto),
        onLongPressStart: (_) {
          setState(() => _presionado = true);
          _onPressStart();
        },
        onLongPressEnd: (_) {
          setState(() => _presionado = false);
          _onPressEnd();
        },
        child: AnimatedScale(
          scale: _presionado ? 0.92 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          child: SizedBox(
            width: KigoDesign.ladoAsistente,
            height: KigoDesign.ladoAsistente,
            child: Opacity(
              opacity: _micDisponible ? 1.0 : 0.4,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _buildHalo(),
                  // Va algo mas chica que el cuadro para dejarle sitio al
                  // halo sin salirse del area pintable.
                  _buildMascota(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Anillo que respira por FUERA de la mascota. Es lo unico que sigue
  /// siendo visible con la yema encima: el centro queda tapado, el borde no.
  Widget _buildHalo() {
    final activo = _presionado ||
        _estado == _EstadoAsistente.escuchando ||
        _estado == _EstadoAsistente.procesando;
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
}
