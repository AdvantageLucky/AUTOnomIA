import 'package:flutter_test/flutter_test.dart';
import 'package:kigo_kiosco/core/services/asistente_presentacion_servicio.dart';

void main() {
  test('empieza sin presentarse y marcarPresentado() lo deja en true', () {
    expect(AsistentePresentacionServicio.yaPresentado, isFalse);
    AsistentePresentacionServicio.marcarPresentado();
    expect(AsistentePresentacionServicio.yaPresentado, isTrue);
  });
}
