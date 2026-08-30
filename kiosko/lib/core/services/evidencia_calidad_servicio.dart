import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as imglib;

/// Resultado de intentar aceptar una captura (INE, rostro): distingue "no se
/// detectó nada" (documento/rostro fuera de encuadre o ilegible) de "se
/// detectó pero la foto salió borrosa" — cada caso necesita un mensaje de
/// reintento distinto (ver spec Should del PRD: "detectar foto borrosa...").
enum CalidadCaptura { ok, noDetectado, borrosa }

/// Detecta fotos borrosas antes de aceptarlas como evidencia (INE, rostro).
/// Usa la varianza del Laplaciano sobre la imagen en escala de grises: una
/// foto nítida tiene bordes marcados (varianza alta), una borrosa los pierde
/// (varianza baja). Métrica estándar y barata de correr on-device.
class EvidenciaCalidadServicio {
  /// Ancho al que se reduce la imagen antes de calcular — el análisis de
  /// nitidez no necesita resolución completa, y reducirla acelera mucho el
  /// cálculo en el hardware del kiosko.
  static const int _anchoAnalisis = 300;

  /// Varianza mínima del Laplaciano para considerar la imagen nítida. Valor
  /// de partida razonable, sin calibrar contra fotos reales del F10 —
  /// ajustar tras probar en el dispositivo físico si rechaza fotos buenas o
  /// acepta fotos borrosas.
  static const double _umbralNitidez = 60.0;

  Future<bool> esNitida(String pathImagen, {double? umbral}) async {
    try {
      final bytes = await File(pathImagen).readAsBytes();
      final imagen = imglib.decodeImage(bytes);
      if (imagen == null) return false;

      final gris = imglib.grayscale(
        imagen.width > _anchoAnalisis
            ? imglib.copyResize(imagen, width: _anchoAnalisis)
            : imagen,
      );

      final varianza = _varianzaLaplaciano(gris);
      return varianza >= (umbral ?? _umbralNitidez);
    } catch (e) {
      debugPrint('Error evaluando calidad de imagen: $e');
      return false;
    }
  }

  /// Kernel de Laplaciano 3x3 estándar: resalta bordes en cualquier
  /// dirección. La varianza de la respuesta es la métrica de nitidez.
  double _varianzaLaplaciano(imglib.Image gris) {
    final w = gris.width;
    final h = gris.height;
    if (w < 3 || h < 3) return 0;

    final respuestas = <double>[];
    for (var y = 1; y < h - 1; y++) {
      for (var x = 1; x < w - 1; x++) {
        final centro = gris.getPixel(x, y).r;
        final arriba = gris.getPixel(x, y - 1).r;
        final abajo = gris.getPixel(x, y + 1).r;
        final izq = gris.getPixel(x - 1, y).r;
        final der = gris.getPixel(x + 1, y).r;
        respuestas.add((arriba + abajo + izq + der - 4 * centro).toDouble());
      }
    }
    if (respuestas.isEmpty) return 0;

    final media = respuestas.reduce((a, b) => a + b) / respuestas.length;
    final sumaCuadrados = respuestas.fold<double>(0, (acc, v) => acc + math.pow(v - media, 2));
    return sumaCuadrados / respuestas.length;
  }
}
