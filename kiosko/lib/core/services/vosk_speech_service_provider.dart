import 'package:vosk_flutter_service/vosk_flutter_service.dart';
import 'package:kigo_kiosco/core/services/vosk_modelo_servicio.dart';
import 'package:kigo_kiosco/core/utils/carga_unica.dart';

/// El plugin nativo de Vosk en Android permite un solo `SpeechService` vivo
/// a la vez para toda la app -- crear un segundo mientras el primero sigue
/// activo falla con `PlatformException(INITIALIZE_FAIL, "SpeechService
/// instance already exist.")`. Como el kiosko usa `Navigator.push` (las
/// pantallas anteriores siguen montadas debajo, no se destruyen), cada
/// pantalla creando su propio `SpeechService` chocaba con la anterior.
///
/// Se comparte uno solo para toda la sesión del kiosko, igual que ya se
/// comparte el modelo (`VoskModeloServicio`) -- cada `AsistenteServicio`
/// sigue siendo su propia instancia por pantalla, pero todas usan el mismo
/// `SpeechService` por debajo.
class VoskSpeechServiceProvider {
  static const _sampleRate = 16000;

  static final CargaUnica<SpeechService> _carga = CargaUnica<SpeechService>(_crear);

  static Future<SpeechService> obtener() => _carga.obtener();

  static Future<SpeechService> _crear() async {
    final model = await VoskModeloServicio.obtener();
    final vosk = VoskFlutterPlugin.instance();
    final recognizer = await vosk.createRecognizer(model: model, sampleRate: _sampleRate);
    return vosk.initSpeechService(recognizer);
  }
}
