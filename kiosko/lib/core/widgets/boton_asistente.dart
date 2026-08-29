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

class _BotonAsistenteState extends State<BotonAsistente> {
  final AsistenteServicio _asistente = AsistenteServicio();
  _EstadoAsistente _estado = _EstadoAsistente.inactivo;
  bool _micDisponible = true;

  @override
  void initState() {
    super.initState();
    _asistente.iniciar().then((ok) {
      if (mounted) setState(() => _micDisponible = ok);
    });
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

    final icono = switch (_estado) {
      _EstadoAsistente.inactivo => Icons.mic_none_rounded,
      _EstadoAsistente.escuchando => Icons.mic_rounded,
      _EstadoAsistente.procesando => Icons.hourglass_top_rounded,
    };

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
          child: Icon(icono, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
