import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as imglib;
import 'package:kigo_kiosco/core/services/evidencia_calidad_servicio.dart';

void main() {
  late Directory tmpDir;

  setUpAll(() {
    tmpDir = Directory.systemTemp.createTempSync('evidencia_calidad_test');
  });

  tearDownAll(() {
    if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
  });

  String guardarPng(String nombre, imglib.Image imagen) {
    final path = '${tmpDir.path}/$nombre.png';
    File(path).writeAsBytesSync(imglib.encodePng(imagen));
    return path;
  }

  test('una imagen con bordes marcados (tablero) se considera nítida', () async {
    final tablero = imglib.Image(width: 200, height: 200);
    for (var y = 0; y < 200; y++) {
      for (var x = 0; x < 200; x++) {
        final claro = ((x ~/ 10) + (y ~/ 10)) % 2 == 0;
        final v = claro ? 255 : 0;
        tablero.setPixelRgb(x, y, v, v, v);
      }
    }
    final path = guardarPng('tablero', tablero);

    final esNitida = await EvidenciaCalidadServicio().esNitida(path);
    expect(esNitida, isTrue);
  });

  test('una imagen plana (sin bordes) se considera borrosa', () async {
    final plana = imglib.Image(width: 200, height: 200);
    for (var y = 0; y < 200; y++) {
      for (var x = 0; x < 200; x++) {
        // Gradiente suave, sin bordes marcados -- simula una foto desenfocada.
        final v = 128 + ((x + y) % 3);
        plana.setPixelRgb(x, y, v, v, v);
      }
    }
    final path = guardarPng('plana', plana);

    final esNitida = await EvidenciaCalidadServicio().esNitida(path);
    expect(esNitida, isFalse);
  });

  test('una ruta que no existe se trata como borrosa, no como error', () async {
    final esNitida = await EvidenciaCalidadServicio().esNitida('${tmpDir.path}/no-existe.png');
    expect(esNitida, isFalse);
  });
}
