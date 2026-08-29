import 'package:flutter/material.dart';
import 'package:kigo_kiosco/core/services/asistente_faq_offline.dart';
import 'package:kigo_kiosco/core/theme/kigo_design.dart';
import 'package:kigo_kiosco/features/registro/services/text_to_speak_servicio.dart';

/// Hoja modal con las preguntas frecuentes fijas — se abre en vez de
/// escuchar cuando el kiosko está sin conexión (sin LLM no hay forma de
/// interpretar una pregunta libre por voz). Tocar una pregunta muestra y
/// lee su respuesta en el momento; no graba ni llama al backend.
Future<void> mostrarFaqOffline(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _FaqOfflineSheet(),
  );
}

class _FaqOfflineSheet extends StatefulWidget {
  const _FaqOfflineSheet();

  @override
  State<_FaqOfflineSheet> createState() => _FaqOfflineSheetState();
}

class _FaqOfflineSheetState extends State<_FaqOfflineSheet> {
  final TextToSpeakServicio _tts = TextToSpeakServicio();
  int? _seleccionada;

  void _seleccionar(int index) {
    setState(() => _seleccionada = index);
    _tts.speak(preguntasFrecuentesOffline[index].respuesta);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sin conexión — preguntas frecuentes',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Toca una pregunta para ver la respuesta',
              style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodySmall?.color),
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < preguntasFrecuentesOffline.length; i++)
              _FilaPregunta(
                faq: preguntasFrecuentesOffline[i],
                expandida: _seleccionada == i,
                onTap: () => _seleccionar(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _FilaPregunta extends StatelessWidget {
  final PreguntaFrecuenteOffline faq;
  final bool expandida;
  final VoidCallback onTap;

  const _FilaPregunta({required this.faq, required this.expandida, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(KigoDesign.radius),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(faq.pregunta, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            if (expandida) ...[
              const SizedBox(height: 6),
              Text(faq.respuesta, style: const TextStyle(fontSize: 14)),
            ],
          ],
        ),
      ),
    );
  }
}
