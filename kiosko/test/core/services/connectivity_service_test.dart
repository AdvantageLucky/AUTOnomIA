import 'package:flutter_test/flutter_test.dart';
import 'package:kigo_kiosco/core/services/connectivity_service.dart';

void main() {
  test('verificarAhora regresa false (no offline) cuando el ping responde true', () async {
    final service = ConnectivityService(pingHealth: () async => true);
    final offline = await service.verificarAhora();
    expect(offline, isFalse);
    expect(service.isOffline, isFalse);
  });

  test('verificarAhora regresa true (offline) cuando el ping falla', () async {
    final service = ConnectivityService(pingHealth: () async => false);
    final offline = await service.verificarAhora();
    expect(offline, isTrue);
    expect(service.isOffline, isTrue);
  });

  test('notifica a los listeners cuando isOffline cambia', () async {
    var pingOk = true;
    final service = ConnectivityService(pingHealth: () async => pingOk);
    var notificaciones = 0;
    service.addListener(() => notificaciones++);

    await service.verificarAhora(); // false -> false, sin cambio, sin notificar
    expect(notificaciones, 0);

    pingOk = false;
    await service.verificarAhora(); // false -> true, notifica
    expect(notificaciones, 1);
  });
}
