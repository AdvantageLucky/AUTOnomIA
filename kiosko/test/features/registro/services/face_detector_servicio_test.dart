import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:kigo_kiosco/features/registro/services/face_detector_servicio.dart';

void main() {
  const tamanoImagen = Size(1000, 1000);

  test('un rostro centrado en la imagen cae dentro del marco', () {
    const caja = Rect.fromLTWH(450, 450, 100, 100); // centro en (500,500)
    expect(estaDentroDelMarco(caja, tamanoImagen), isTrue);
  });

  test('un rostro pegado a la esquina queda fuera del marco', () {
    const caja = Rect.fromLTWH(0, 0, 100, 100); // centro en (50,50)
    expect(estaDentroDelMarco(caja, tamanoImagen), isFalse);
  });

  test('un rostro justo en el borde de la fracción central cae dentro', () {
    // fraccion 0.6 -> margen de 200px por lado (1000 * 0.4 / 2) -> zona
    // válida de x/y en [200, 800].
    const caja = Rect.fromLTWH(190, 490, 20, 20); // centro en (200,500)
    expect(estaDentroDelMarco(caja, tamanoImagen, fraccion: 0.6), isTrue);
  });

  test('una fracción más chica es más estricta', () {
    const caja = Rect.fromLTWH(300, 450, 100, 100); // centro en (350,500)
    // fraccion 0.6 -> zona válida [200,800]: 350 cae dentro.
    expect(estaDentroDelMarco(caja, tamanoImagen, fraccion: 0.6), isTrue);
    // fraccion 0.2 -> zona válida [400,600]: 350 cae fuera.
    expect(estaDentroDelMarco(caja, tamanoImagen, fraccion: 0.2), isFalse);
  });
}
