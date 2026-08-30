import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kigo_kiosco/core/models/campo_extraido.dart';
import 'package:kigo_kiosco/core/services/asistente_servicio.dart';
import 'package:kigo_kiosco/core/services/connectivity_service.dart';
import 'package:kigo_kiosco/core/theme/kigo_design.dart';
import 'package:kigo_kiosco/core/widgets/faq_offline_sheet.dart';

enum _EstadoAsistente { inactivo, escuchando, procesando }

/// Botón push-to-talk compartido: mantener presionado para hablar, soltar
/// para enviar. [tipoCampo] null => pregunta libre (WelcomeView, respondida
/// por voz). [tipoCampo] 'placa'|'destino' => extracción de campo (pantallas
/// de confirmación del flujo vehicular, silenciosa).
class BotonAsistente extends StatefulWidget {
  final String? tipoCampo;
  final void Function(String respuesta) onRespuestaLibre;
  final void Function(CampoExtraido) onCampoExtraido;

  const BotonAsistente({
    super.key,
    this.tipoCampo,
    required this.onRespuestaLibre,
    required this.onCampoExtraido,
  });

  @override
  State<BotonAsistente> createState() => _BotonAsistenteState();
}

class _BotonAsistenteState extends State<BotonAsistente> with SingleTickerProviderStateMixin {
  final AsistenteServicio _asistente = AsistenteServicio();
  _EstadoAsistente _estado = _EstadoAsistente.inactivo;
  bool _micDisponible = true;

  /// Anima las barras del ecualizador mientras `_estado == escuchando` — el
  /// simple cambio de ícono (mic_none -> mic_rounded) que había antes era
  /// demasiado sutil para notarse de reojo mientras alguien habla.
  late final AnimationController _ondasCtrl;

  @override
  void initState() {
    super.initState();
    _ondasCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
    _asistente.iniciar().then((ok) {
      if (mounted) setState(() => _micDisponible = ok);
    });
  }

  @override
  void dispose() {
    _ondasCtrl.dispose();
    super.dispose();
  }

  Future<void> _onPressStart() async {
    if (!_micDisponible) return;
    setState(() => _estado = _EstadoAsistente.escuchando);

    await _asistente.escuchar(
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
    );
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
        child: GestureDetector(
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
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _micDisponible ? KigoDesign.brand : KigoDesign.brand.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(KigoDesign.radius),
          ),
          child: _buildContenido(),
        ),
      ),
    );
  }

  Widget _buildContenido() {
    if (_estado == _EstadoAsistente.escuchando) return _buildOndas();

    final icono = switch (_estado) {
      _EstadoAsistente.inactivo => Icons.mic_none_rounded,
      _EstadoAsistente.escuchando => Icons.mic_rounded, // no llega aquí, cubierto arriba
      _EstadoAsistente.procesando => Icons.hourglass_top_rounded,
    };
    return Icon(icono, color: Colors.white, size: 20);
  }

  /// Cuatro barras tipo ecualizador, cada una desfasada respecto a las demás
  /// sobre el mismo ciclo, en onda triangular (sube y baja parejo).
  Widget _buildOndas() {
    return AnimatedBuilder(
      animation: _ondasCtrl,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) {
            final t = (_ondasCtrl.value + i * 0.15) % 1.0;
            final triangular = 1 - (2 * (t - 0.5)).abs(); // 0..1..0
            final alto = 8 + 12 * triangular;
            return Container(
              width: 3,
              height: alto,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}
