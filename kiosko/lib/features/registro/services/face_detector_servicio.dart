import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Área mínima del cuadro delimitador para dar por bueno un rostro: descarta
/// caras diminutas al fondo del encuadre.
const double areaMinimaRostro = 8000;

class FaceDetectorServicio {
  final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      enableClassification: false,
      enableLandmarks: false,
    ),
  );

  /// Retorna true si la imagen contiene un rostro con tamaño suficiente.
  Future<bool> tieneRostroValido(String pathImagen) async {
    final inputImage = InputImage.fromFilePath(pathImagen);

    try {
      final List<Face> rostros = await _detector.processImage(inputImage);
      if (rostros.isEmpty) return false;

      final caja = rostros.first.boundingBox;
      return caja.width * caja.height > areaMinimaRostro;
    } catch (e) {
      debugPrint("Error en detección de rostro: $e");
      return false;
    }
  }

  /// Cerrar el detector es responsabilidad de quien lo instancia, al desmontar
  /// la pantalla. Antes se cerraba dentro de `tieneRostroValido`, así que a
  /// partir de la segunda foto el servicio quedaba inservible y cada llamada
  /// forzaba a ML Kit a reinicializarse.
  void dispose() => _detector.close();
}
