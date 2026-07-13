import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectorServicio {
  final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      enableClassification: false,
      enableLandmarks: false,
    ),
  );

  /// Retorna true si la imagen contiene exactamente un rostro con tamaño suficiente.
  Future<bool> tieneRostroValido(String pathImagen) async {
    final inputImage = InputImage.fromFilePath(pathImagen);

    try {
      final List<Face> rostros = await _detector.processImage(inputImage);

      if (rostros.isEmpty) return false;

      // Verificamos que el rostro sea suficientemente grande (no una cara diminuta al fondo)
      final rostro = rostros.first;
      final area = rostro.boundingBox.width * rostro.boundingBox.height;
      return area > 8000;
    } catch (e) {
      print("Error en detección de rostro: $e");
      return false;
    } finally {
      _detector.close();
    }
  }
}