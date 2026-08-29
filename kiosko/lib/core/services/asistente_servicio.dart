import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:kigo_kiosco/core/models/campo_extraido.dart';
import 'package:kigo_kiosco/features/registro/services/kiosko_servicio.dart';
import 'package:kigo_kiosco/features/registro/services/text_to_speak_servicio.dart';

/// Envuelve speech_to_text (push-to-talk, nunca escucha continua) y decide,
/// según [tipoCampo], si la transcripción se manda a /preguntar (null, Q&A
/// libre) o a /extraer-campo (placa|destino). Nunca dispara acciones ni
/// navegación — solo entrega el resultado al caller vía los callbacks.
///
/// La escucha termina de dos formas: el caller suelta el botón y llama
/// [detener] (caso normal), o pasan 15s sin soltar (límite duro de
/// seguridad, [listenFor] de speech_to_text). Nunca espera un tiempo fijo
/// sin importar cuándo soltó el visitante.
class AsistenteServicio {
  final stt.SpeechToText _stt = stt.SpeechToText();
  final TextToSpeakServicio _tts = TextToSpeakServicio();
  final KioskoServicio _kioskoServicio = KioskoServicio();

  static const _duracionMaxima = Duration(seconds: 15);

  Completer<String>? _resultado;
  String _transcripcionParcial = '';

  Future<bool> iniciar() => _stt.initialize();

  /// [tipoCampo] null => pregunta libre (Q&A hablada por TTS).
  /// [tipoCampo] 'placa'|'destino' => extracción de campo (silenciosa, sin TTS).
  Future<void> escuchar({
    String? tipoCampo,
    required void Function(String respuesta) onRespuestaLibre,
    required void Function(CampoExtraido) onCampoExtraido,
    required void Function() onNoEntendido,
  }) async {
    _transcripcionParcial = '';
    final completer = Completer<String>();
    _resultado = completer;

    await _stt.listen(
      onResult: (result) {
        _transcripcionParcial = result.recognizedWords;
        if (result.finalResult && !completer.isCompleted) {
          completer.complete(_transcripcionParcial);
        }
      },
      // límite duro de seguridad, no la duración normal de uso
      listenOptions: stt.SpeechListenOptions(listenFor: _duracionMaxima),
    );

    final transcripcionFinal = await completer.future;
    _resultado = null;

    if (transcripcionFinal.trim().isEmpty) {
      onNoEntendido();
      return;
    }

    if (tipoCampo == null) {
      final respuesta = await _kioskoServicio.preguntarAsistente(transcripcionFinal);
      await _tts.speak(respuesta);
      onRespuestaLibre(respuesta);
    } else {
      final extraido = await _kioskoServicio.extraerCampoAsistente(transcripcionFinal, tipoCampo);
      onCampoExtraido(extraido);
    }
  }

  /// Se llama cuando el visitante suelta el botón — corta la escucha ahí
  /// mismo en vez de esperar los 15s del límite de seguridad.
  Future<void> detener() async {
    await _stt.stop();
    final completer = _resultado;
    if (completer != null && !completer.isCompleted) {
      completer.complete(_transcripcionParcial);
    }
  }
}
