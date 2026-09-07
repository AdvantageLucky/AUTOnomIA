import 'dart:io';
import 'dart:ui' show Rect, Size;

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as imglib;

/// Chequeo liviano de "¿hay un rostro válido en este frame?" -- portado de
/// kiosko/lib/features/registro/services/face_detector_servicio.dart. Se usa
/// para el sondeo automático (cada pocos cientos de ms); el cálculo pesado
/// del embedding (ReconocimientoFacialServicio.calcularEmbedding, que además
/// corre el modelo TFLite) solo se ejecuta una vez, sobre la foto ya
/// confirmada -- correrlo en cada intento del sondeo sería demasiado lento
/// para sentirse "automático".
const double areaMinimaRostro = 8000;

/// Fracción central de la imagen que se considera "dentro del óvalo guía".
const double _fraccionMarcoCentral = 0.6;

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

  /// true si la imagen contiene un rostro con tamaño suficiente Y centrado
  /// dentro del óvalo guía (no solo "hay una cara en algún lado").
  Future<bool> tieneRostroValido(String pathImagen) async {
    final inputImage = InputImage.fromFilePath(pathImagen);

    try {
      final List<Face> rostros = await _detector.processImage(inputImage);
      if (rostros.isEmpty) return false;

      final caja = rostros.first.boundingBox;
      if (caja.width * caja.height <= areaMinimaRostro) return false;

      final bytes = await File(pathImagen).readAsBytes();
      final imagen = imglib.decodeImage(bytes);
      if (imagen == null) return false;

      return estaDentroDelMarco(caja, Size(imagen.width.toDouble(), imagen.height.toDouble()));
    } catch (e) {
      debugPrint("Error en detección de rostro: $e");
      return false;
    }
  }

  void dispose() => _detector.close();
}
