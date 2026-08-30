import 'package:flutter_test/flutter_test.dart';
import 'package:kigo_kiosco/core/services/asistente_controller.dart';

void main() {
  test('decir() guarda el texto y notifica listeners', () {
    final controller = AsistenteController();
    var notificado = false;
    controller.addListener(() => notificado = true);

    controller.decir('Hola, soy tu asistente');

    expect(notificado, isTrue);
    expect(controller.textoPendiente, 'Hola, soy tu asistente');
  });

  test('cada llamada a decir() vuelve a notificar, incluso con texto repetido', () {
    final controller = AsistenteController();
    var conteo = 0;
    controller.addListener(() => conteo++);

    controller.decir('Paso uno');
    controller.decir('Paso uno');

    expect(conteo, 2);
  });
}
