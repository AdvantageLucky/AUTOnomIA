import 'package:vosk_flutter_service/vosk_flutter_service.dart';
import 'package:kigo_kiosco/core/utils/carga_unica.dart';

/// Carga el modelo de español de Vosk una sola vez por sesión del kiosko,
/// compartido entre todas las instancias de AsistenteServicio -- cada
/// pantalla con mascota crea la suya, y sin este cacheo cada una volvería
/// a parsear los 39MB del modelo desde cero.
class VoskModeloServicio {
  static const _rutaAsset = 'assets/models/vosk-model-small-es-0.42.zip';

  static final CargaUnica<Model> _carga = CargaUnica<Model>(_cargar);

  static Future<Model> obtener() => _carga.obtener();

  static Future<Model> _cargar() async {
    final modelPath = await ModelLoader().loadFromAssets(_rutaAsset);
    return VoskFlutterPlugin.instance().createModel(modelPath);
  }
}
