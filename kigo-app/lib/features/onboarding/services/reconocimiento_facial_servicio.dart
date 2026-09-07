import 'dart:io';
import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as imglib;
import 'package:tflite_flutter/tflite_flutter.dart';

/// Calcula la huella facial (embedding) de un rostro a partir de una foto,
/// usando un modelo MobileFaceNet corriendo localmente en el dispositivo —
/// portado tal cual de kiosko/lib/features/residente/services/
/// reconocimiento_facial_servicio.dart, mismo modelo .tflite, mismo
/// esquema de normalización, para que el vector resultante sea comparable
/// con los que ya genera el kiosko.
class ReconocimientoFacialServicio {
  static const _modeloAsset = 'assets/models/mobilefacenet.tflite';
  static const _tamanoEntrada = 112;
  static const _dimensionesEmbedding = 192;

  Interpreter? _interpreter;

  Future<Interpreter> _obtenerInterprete() async {
    return _interpreter ??= await Interpreter.fromAsset(_modeloAsset);
  }

  /// Regresa el embedding del primer rostro encontrado en la imagen, o null
  /// si no se detectó ningún rostro o no se pudo procesar.
  Future<List<double>?> calcularEmbedding(String pathImagen) async {
    final detector = FaceDetector(
      options: FaceDetectorOptions(performanceMode: FaceDetectorMode.accurate),
    );

    try {
      final rostros = await detector.processImage(InputImage.fromFilePath(pathImagen));
      if (rostros.isEmpty) return null;

      final bytes = await File(pathImagen).readAsBytes();
      final imagen = imglib.decodeImage(bytes);
      if (imagen == null) return null;

      final recorte = _recortarRostro(imagen, rostros.first.boundingBox);
      final redimensionada = imglib.copyResize(
        recorte,
        width: _tamanoEntrada,
        height: _tamanoEntrada,
      );

      final entrada = _imagenAEntradaModelo(redimensionada);
      final salida = List.generate(1, (_) => List.filled(_dimensionesEmbedding, 0.0));

      final interprete = await _obtenerInterprete();
      interprete.run(entrada, salida);

      return List<double>.from(salida[0] as List);
    } catch (e) {
      debugPrint('Error calculando embedding facial: $e');
      return null;
    } finally {
      detector.close();
    }
  }

  imglib.Image _recortarRostro(imglib.Image imagen, Rect caja) {
    const margen = 0.15;
    final margenX = caja.width * margen;
    final margenY = caja.height * margen;

    final x = (caja.left - margenX).round().clamp(0, imagen.width - 1);
    final y = (caja.top - margenY).round().clamp(0, imagen.height - 1);
    final ancho = (caja.width + margenX * 2).round().clamp(1, imagen.width - x);
    final alto = (caja.height + margenY * 2).round().clamp(1, imagen.height - y);

    return imglib.copyCrop(imagen, x: x, y: y, width: ancho, height: alto);
  }

  List _imagenAEntradaModelo(imglib.Image imagen) {
    return [
      List.generate(
        imagen.height,
        (y) => List.generate(imagen.width, (x) {
          final pixel = imagen.getPixel(x, y);
          return [
            (pixel.r - 128) / 128,
            (pixel.g - 128) / 128,
            (pixel.b - 128) / 128,
          ];
        }),
      ),
    ];
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}
