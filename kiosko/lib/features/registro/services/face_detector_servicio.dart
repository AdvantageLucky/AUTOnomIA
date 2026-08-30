import 'dart:io';
import 'dart:ui' show Rect, Size;

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as imglib;

/// Área mínima del cuadro delimitador para dar por bueno un rostro: descarta
/// caras diminutas al fondo del encuadre.
const double areaMinimaRostro = 8000;

/// Fracción central de la imagen que se considera "dentro del óvalo/círculo
/// guía" -- 0.6 = el 60% central en ancho y alto. No es una transformación
/// pixel-exacta del óvalo dibujado en pantalla a coordenadas de la foto (eso
/// requeriría calibrar contra la rotación/recorte reales de la cámara del
/// F10 físico); es una aproximación proporcional razonable, ajustable tras
/// probar en el dispositivo real si rechaza rostros bien centrados o acepta
/// rostros claramente fuera de la guía.
const double _fraccionMarcoCentral = 0.6;

/// true si el centro de [caja] cae dentro de la región central de la
/// imagen de [tamanoImagen] -- usado para rechazar rostros detectados fuera
/// del óvalo/círculo guía que se le muestra al visitante (antes se
/// aceptaba cualquier rostro en cualquier parte del encuadre).
bool estaDentroDelMarco(Rect caja, Size tamanoImagen, {double fraccion = _fraccionMarcoCentral}) {
  final centroX = caja.left + caja.width / 2;
  final centroY = caja.top + caja.height / 2;

  final margenX = tamanoImagen.width * (1 - fraccion) / 2;
  final margenY = tamanoImagen.height * (1 - fraccion) / 2;

  return centroX >= margenX &&
      centroX <= tamanoImagen.width - margenX &&
      centroY >= margenY &&
      centroY <= tamanoImagen.height - margenY;
}

class FaceDetectorServicio {
  final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      enableClassification: false,
      enableLandmarks: false,
    ),
  );

  /// Retorna true si la imagen contiene un rostro con tamaño suficiente Y
  /// centrado dentro del óvalo guía (no solo "hay una cara en algún lado
  /// de la foto").
  Future<bool> tieneRostroValido(String pathImagen) async {
    final inputImage = InputImage.fromFilePath(pathImagen);

    try {
      final List<Face> rostros = await _detector.processImage(inputImage);
      if (rostros.isEmpty) return false;

      final caja = rostros.first.boundingBox;
      if (caja.width * caja.height <= areaMinimaRostro) return false;

      // `InputImage.fromFilePath` nunca llena `metadata` (solo lo hace
      // `fromBytes`) -- se decodifica el archivo aparte para saber el
      // tamaño real de la foto y poder validar la posición del rostro.
      final bytes = await File(pathImagen).readAsBytes();
      final imagen = imglib.decodeImage(bytes);
      if (imagen == null) return false;

      return estaDentroDelMarco(caja, Size(imagen.width.toDouble(), imagen.height.toDouble()));
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
