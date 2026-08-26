import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as imglib;
import 'package:kigo_kiosco/features/registro/services/face_detector_servicio.dart'
    show areaMinimaRostro;
import 'package:tflite_flutter/tflite_flutter.dart';

const int _tamanoEntrada = 112;
const int _dimensionesEmbedding = 192;

/// Calcula la huella facial (embedding) de un rostro a partir de una foto,
/// usando un modelo MobileFaceNet corriendo localmente en el dispositivo.
/// La imagen nunca sale del kiosko: solo el vector resultante viaja al backend.
///
/// Todo el trabajo pesado corre fuera del isolate de UI. En el kiosko
/// (Octa-Core 1.8GHz, 2GB) decodificar el JPEG y armar el tensor en Dart puro
/// bloqueaba el hilo de interfaz varias décimas de segundo por foto, que es lo
/// que se veía como tirones en la vista previa.
class ReconocimientoFacialServicio {
  static const _modeloAsset = 'assets/models/mobilefacenet.tflite';

  // El detector se crea una sola vez: instanciarlo por llamada obliga a ML Kit
  // a recargar su modelo nativo cada vez.
  final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(performanceMode: FaceDetectorMode.accurate),
  );

  Interpreter? _interpreter;
  IsolateInterpreter? _interpreteAislado;

  Future<IsolateInterpreter> _obtenerInterprete() async {
    if (_interpreteAislado != null) return _interpreteAislado!;
    final interpreter = await Interpreter.fromAsset(_modeloAsset);
    _interpreter = interpreter;
    _interpreteAislado =
        await IsolateInterpreter.create(address: interpreter.address);
    return _interpreteAislado!;
  }

  /// Regresa el embedding del primer rostro encontrado en la imagen, o null si
  /// no se detectó ningún rostro, si es demasiado pequeño, o si no se pudo
  /// procesar. La validación de tamaño va aquí para no tener que correr una
  /// segunda pasada de ML Kit sobre la misma foto.
  Future<List<double>?> calcularEmbedding(String pathImagen) async {
    try {
      final rostros =
          await _detector.processImage(InputImage.fromFilePath(pathImagen));
      if (rostros.isEmpty) return null;

      final caja = rostros.first.boundingBox;
      if (caja.width * caja.height <= areaMinimaRostro) return null;

      final bytes = await File(pathImagen).readAsBytes();

      // Solo se capturan valores enviables entre isolates (bytes y doubles).
      final left = caja.left;
      final top = caja.top;
      final ancho = caja.width;
      final alto = caja.height;

      final plano = await Isolate.run(
        () => _prepararTensor(bytes, left, top, ancho, alto),
      );
      if (plano == null) return null;

      final entrada =
          plano.reshape<double>([1, _tamanoEntrada, _tamanoEntrada, 3]);
      final salida =
          List.generate(1, (_) => List.filled(_dimensionesEmbedding, 0.0));

      final interprete = await _obtenerInterprete();
      await interprete.run(entrada, salida);

      return List<double>.from(salida[0]);
    } catch (e) {
      debugPrint('Error calculando embedding facial: $e');
      return null;
    }
  }

  Future<void> dispose() async {
    await _detector.close();
    await _interpreteAislado?.close();
    _interpreteAislado = null;
    _interpreter?.close();
    _interpreter = null;
  }
}

/// Decodifica, recorta, redimensiona y normaliza la foto a un tensor plano.
///
/// Corre dentro de `Isolate.run`: `package:image` es Dart puro y es la parte
/// más cara de todo el proceso.
Float32List? _prepararTensor(
  Uint8List bytes,
  double left,
  double top,
  double ancho,
  double alto,
) {
  final imagen = imglib.decodeImage(bytes);
  if (imagen == null) return null;

  // El cuadro de ML Kit suele venir muy ajustado; se agrega margen y se acota
  // para que no se salga de la imagen.
  const margen = 0.15;
  final margenX = ancho * margen;
  final margenY = alto * margen;

  final x = (left - margenX).round().clamp(0, imagen.width - 1);
  final y = (top - margenY).round().clamp(0, imagen.height - 1);
  final w = (ancho + margenX * 2).round().clamp(1, imagen.width - x);
  final h = (alto + margenY * 2).round().clamp(1, imagen.height - y);

  final recorte = imglib.copyCrop(imagen, x: x, y: y, width: w, height: h);
  final redimensionada = imglib.copyResize(
    recorte,
    width: _tamanoEntrada,
    height: _tamanoEntrada,
  );

  // Normalización a [-1,1]: mismo esquema con el que se exportó MobileFaceNet.
  final salida = Float32List(_tamanoEntrada * _tamanoEntrada * 3);
  var i = 0;
  for (var fila = 0; fila < _tamanoEntrada; fila++) {
    for (var col = 0; col < _tamanoEntrada; col++) {
      final pixel = redimensionada.getPixel(col, fila);
      salida[i++] = (pixel.r - 128) / 128;
      salida[i++] = (pixel.g - 128) / 128;
      salida[i++] = (pixel.b - 128) / 128;
    }
  }
  return salida;
}
