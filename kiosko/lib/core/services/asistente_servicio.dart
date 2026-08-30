import 'dart:async';
import 'package:flutter/foundation.dart';
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

    // Red de seguridad adicional: normalmente `detener()` o el propio
    // límite de `listenFor` completan este future, pero un cuelgue del
    // plugin STT no debe dejar el botón atorado en "procesando" para
    // siempre -- por eso un timeout algo más largo que _duracionMaxima.
    final transcripcionFinal = await completer.future.timeout(
      _duracionMaxima + const Duration(seconds: 5),
      onTimeout: () => _transcripcionParcial,
    );
    _resultado = null;

    if (transcripcionFinal.trim().isEmpty) {
      onNoEntendido();
      return;
    }

    if (tipoCampo == null) {
      final respuesta = await _kioskoServicio.preguntarAsistente(transcripcionFinal);
      // El callback regresa el ícono a "inactivo" de inmediato; hablar la
      // respuesta no debe bloquear el estado visual mientras dura el TTS
      // (antes el ícono se quedaba en "procesando" todo ese tiempo).
      onRespuestaLibre(respuesta);
      unawaited(_tts.speak(respuesta));
    } else {
      final extraido = await _kioskoServicio.extraerCampoAsistente(transcripcionFinal, tipoCampo);
      onCampoExtraido(extraido);
    }
  }

  /// Se llama cuando el visitante suelta el botón — corta la escucha ahí
  /// mismo en vez de esperar los 15s del límite de seguridad. Nunca debe
  /// dejar el completer sin resolver, así falle `_stt.stop()`.
  Future<void> detener() async {
    try {
      await _stt.stop();
    } catch (e) {
      debugPrint('Error deteniendo STT: $e');
    } finally {
      final completer = _resultado;
      if (completer != null && !completer.isCompleted) {
        completer.complete(_transcripcionParcial);
      }
    }
  }
}
