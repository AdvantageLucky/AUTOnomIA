import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kigo_kiosco/core/models/campo_extraido.dart';
import 'package:kigo_kiosco/core/services/asistente_controller.dart';
import 'package:kigo_kiosco/core/services/asistente_servicio.dart';
import 'package:kigo_kiosco/core/services/connectivity_service.dart';
import 'package:kigo_kiosco/core/theme/kigo_design.dart';
import 'package:kigo_kiosco/core/widgets/faq_offline_sheet.dart';
import 'package:kigo_kiosco/core/widgets/mascota_asistente.dart';
import 'package:kigo_kiosco/core/widgets/presionable.dart';
import 'package:kigo_kiosco/features/registro/services/text_to_speak_servicio.dart';

enum _EstadoAsistente { inactivo, escuchando, procesando, hablando }

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
  _EstadoAsistente _estado = _EstadoAsistente.inactivo;
  bool _micDisponible = true;

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

    // Sin red, el llenado de campos (placa/destino) no tiene alternativa —
    // necesita el LLM sí o sí. La pregunta libre (tipoCampo null) sí tiene
    // un modo sin conexión: el FAQ fijo, en vez de escuchar.
    if (offline && widget.tipoCampo != null) {
      return Tooltip(
        message: 'Sin conexión — usa el teclado/selector manual',
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: KigoDesign.brand.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(KigoDesign.radius),
          ),
          child: const Icon(Icons.mic_off_rounded, color: Colors.white, size: 20),
        ),
      );
    }

    if (offline) {
      return Tooltip(
        message: 'Sin conexión — toca para ver preguntas frecuentes',
        child: Presionable(
          onTap: () => mostrarFaqOffline(context),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: KigoDesign.brand,
              borderRadius: BorderRadius.circular(KigoDesign.radius),
            ),
            child: const Icon(Icons.help_outline_rounded, color: Colors.white, size: 20),
          ),
        ),
      );
    }

    return Tooltip(
      message: _micDisponible
          ? 'Mantén presionado para hablar'
          : 'Activa el permiso de micrófono para usar el asistente',
      child: GestureDetector(
        onLongPressStart: (_) => _onPressStart(),
        onLongPressEnd: (_) => _onPressEnd(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Opacity(
            opacity: _micDisponible ? 1.0 : 0.4,
            child: _buildMascota(),
          ),
        ),
      ),
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
      ),
    );
  }
}
