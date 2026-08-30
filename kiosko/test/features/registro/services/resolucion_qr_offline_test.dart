import 'package:flutter_test/flutter_test.dart';
import 'package:kigo_kiosco/features/registro/services/resolucion_qr_offline.dart';

void main() {
  test('con match de residente, resuelve miembro y no importa si tambien hay invitacion', () {
    final r = resolverQrOffline(
      residenteMatch: {'nombre': 'Ana', 'apellido_paterno': 'Ruiz', 'casa_destino': 'Casa 1'},
      invitacionMatch: {'titular': 'Ana Invitada', 'casa_destino': 'Casa 2'},
    );
    expect(r.estado, EstadoQrOffline.miembro);
    expect(r.nombre, 'Ana Ruiz');
    expect(r.casaDestino, 'Casa 1');
  });

  test('sin match de residente pero con invitacion activa, resuelve invitado', () {
    final r = resolverQrOffline(
      residenteMatch: null,
      invitacionMatch: {'titular': 'Beto', 'casa_destino': 'Casa 2'},
    );
    expect(r.estado, EstadoQrOffline.invitado);
    expect(r.nombre, 'Beto');
    expect(r.casaDestino, 'Casa 2');
  });

  test('sin match de ninguno, resuelve ninguno -- este es el caso del bug original', () {
    final r = resolverQrOffline(residenteMatch: null, invitacionMatch: null);
    expect(r.estado, EstadoQrOffline.ninguno);
  });
}
