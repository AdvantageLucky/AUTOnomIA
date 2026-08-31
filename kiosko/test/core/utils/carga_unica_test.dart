import 'package:flutter_test/flutter_test.dart';
import 'package:kigo_kiosco/core/utils/carga_unica.dart';

void main() {
  test('obtener() solo invoca el cargador una vez, incluso con llamadas concurrentes', () async {
    var conteo = 0;
    final carga = CargaUnica<int>(() async {
      conteo++;
      await Future.delayed(const Duration(milliseconds: 10));
      return 42;
    });

    final resultados = await Future.wait([
      carga.obtener(),
      carga.obtener(),
      carga.obtener(),
    ]);

    expect(conteo, 1);
    expect(resultados, [42, 42, 42]);
  });

  test('llamadas despues de completar reusan el valor cacheado sin recargar', () async {
    var conteo = 0;
    final carga = CargaUnica<String>(() async {
      conteo++;
      return 'listo';
    });

    await carga.obtener();
    await carga.obtener();

    expect(conteo, 1);
  });
}
