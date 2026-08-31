import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:vosk_flutter_service/vosk_flutter_service.dart';
import 'package:kigo_kiosco/core/models/campo_extraido.dart';
import 'package:kigo_kiosco/core/services/vosk_speech_service_provider.dart';
import 'package:kigo_kiosco/features/registro/services/kiosko_servicio.dart';
import 'package:kigo_kiosco/features/registro/services/text_to_speak_servicio.dart';

/// Envuelve Vosk (push-to-talk, nunca escucha continua) y decide, según
/// [tipoCampo], si la transcripción se manda a /preguntar (null, Q&A
/// libre) o a /extraer-campo (placa|destino). Nunca dispara acciones ni
/// navegación — solo entrega el resultado al caller vía los callbacks.
///
/// La escucha termina de dos formas: el caller suelta el botón y llama
/// [detener] (caso normal), o pasan 15s sin soltar (límite duro de
/// seguridad, implementado a mano aquí -- Vosk, a diferencia de
/// speech_to_text, no trae un parámetro de duración máxima integrado).
class AsistenteServicio {
  static const _duracionMaxima = Duration(seconds: 15);

  final TextToSpeakServicio _tts = TextToSpeakServicio();
  final KioskoServicio _kioskoServicio = KioskoServicio();

  SpeechService? _speechService;
  StreamSubscription<String>? _resultSub;
  Completer<String>? _resultado;
  Timer? _limiteSeguridad;

  /// Detalle del último error de `iniciar()` -- diagnóstico temporal para
  /// poder ver en pantalla (sin ADB/logcat) por qué falló en un dispositivo
  /// real, mientras se confirma la causa. `null` si `iniciar()` nunca falló.
  String? ultimoError;

  Future<bool> iniciar() async {
    try {
      // El plugin nativo solo permite un SpeechService vivo a la vez en
      // toda la app -- se comparte uno solo para toda la sesión del
      // kiosko (ver VoskSpeechServiceProvider) en vez de crear uno nuevo
      // por pantalla, que chocaba con el de la pantalla anterior (sigue
      // montada debajo tras un Navigator.push).
      _speechService = await VoskSpeechServiceProvider.obtener();
      return true;
    } catch (e) {
      debugPrint('Error iniciando Vosk: $e');
      ultimoError = e.toString();
      return false;
    }
  }

  /// [tipoCampo] null => pregunta libre (Q&A hablada por TTS).
  /// [tipoCampo] 'placa'|'destino' => extracción de campo (silenciosa, sin TTS).
  Future<void> escuchar({
    String? tipoCampo,
    required void Function(String respuesta) onRespuestaLibre,
    required void Function(CampoExtraido) onCampoExtraido,
    required void Function() onNoEntendido,
  }) async {
    final speechService = _speechService;
    if (speechService == null) {
      onNoEntendido();
      return;
    }

    final completer = Completer<String>();
    _resultado = completer;

    _resultSub?.cancel();
    _resultSub = speechService.onResult().listen((jsonResultado) {
      if (completer.isCompleted) return;
      completer.complete(_extraerTexto(jsonResultado));
    });

    await speechService.start();
    // límite duro de seguridad -- Vosk no tiene un `listenFor` propio como
    // speech_to_text, así que se implementa a mano: si nadie soltó el
    // botón en 15s, se corta la escucha sola.
    _limiteSeguridad = Timer(_duracionMaxima, () {
      if (!completer.isCompleted) speechService.stop();
    });

    // red de seguridad adicional: aunque detener()/el límite de arriba
    // deberían completar esto siempre, un cuelgue del plugin no debe
    // dejar el botón atorado en "procesando" para siempre.
    final transcripcionFinal = await completer.future.timeout(
      _duracionMaxima + const Duration(seconds: 5),
      onTimeout: () => '',
    );
    _limiteSeguridad?.cancel();
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

  /// Extrae el campo "text" del JSON crudo que emite Vosk en sus
  /// resultados finales (`{"text": "..."}`) -- si el JSON viene vacío o
  /// mal formado, se trata como "no se entendió nada" en vez de lanzar.
  String _extraerTexto(String jsonResultado) {
    try {
      final data = jsonDecode(jsonResultado) as Map<String, dynamic>;
      return (data['text'] as String?)?.trim() ?? '';
    } catch (e) {
      debugPrint('Error parseando resultado de Vosk: $e');
      return '';
    }
  }

  /// Se llama cuando el visitante suelta el botón — corta la escucha ahí
  /// mismo en vez de esperar los 15s del límite de seguridad. Nunca debe
  /// dejar el completer sin resolver, así falle `speechService.stop()`.
  Future<void> detener() async {
    _limiteSeguridad?.cancel();
    try {
      await _speechService?.stop();
    } catch (e) {
      debugPrint('Error deteniendo Vosk: $e');
    } finally {
      final completer = _resultado;
      if (completer != null && !completer.isCompleted) {
        completer.complete('');
      }
    }
  }

  /// Suelta la suscripción/timer de esta instancia -- el SpeechService en
  /// sí es compartido para toda la sesión del kiosko (ver
  /// VoskSpeechServiceProvider) y sigue vivo para las demás pantallas, así
  /// que no se libera aquí.
  Future<void> dispose() async {
    _limiteSeguridad?.cancel();
    await _resultSub?.cancel();
    _speechService = null;
  }
}
