import 'package:flutter_test/flutter_test.dart';
import 'package:kigo_user/models/invitacion_model.dart';
import 'package:kigo_user/models/visita_historial_model.dart';
import 'package:kigo_user/utils/fechas.dart';

/// El backend serializa las fechas en UTC (con la Z al final). Estas pruebas
/// fijan que lo que se pinta sea la hora del usuario y no la UTC cruda: el
/// bug original mostraba una entrada de las 20:21 en el kiosko como
/// "04 Sep · 02:21", seis horas adelantada y con el dia ya cambiado.
///
/// Se usa `DateTime.now().timeZoneOffset` en vez de asumir UTC-6 para que la
/// prueba valga en cualquier maquina, incluido un CI en UTC (donde la
/// conversion es la identidad y la prueba simplemente no distingue nada,
/// pero tampoco miente).
void main() {
  group('fechaCortaLocal', () {
    test('convierte a la zona del dispositivo antes de leer el dia', () {
      final utc = DateTime.utc(2026, 9, 4, 2, 21);
      final local = utc.toLocal();

      expect(fechaCortaLocal(utc), '${local.day}/${local.month}/${local.year}');
    });

    test('una fecha que ya es local se imprime tal cual', () {
      final local = DateTime(2026, 9, 3, 20, 21);

      expect(fechaCortaLocal(local), '3/9/2026');
    });
  });

  group('fechas que vienen del JSON del backend', () {
    test('created_at con Z se parsea como UTC', () {
      final visita = VisitaHistorialModel.fromJson(_jsonVisita('2026-09-04T02:21:00Z'));

      expect(visita.createdAt.isUtc, isTrue,
          reason: 'si esto deja de ser UTC, revisar los toLocal() de las vistas');
    });

    test('expires_at con Z se parsea como UTC', () {
      final inv = InvitacionModel.fromJson(_jsonInvitacion('2026-09-10T06:00:00Z'));

      expect(inv.expiresAt!.isUtc, isTrue);
    });

    test('el dia mostrado es el local, no el UTC', () {
      final visita = VisitaHistorialModel.fromJson(_jsonVisita('2026-09-04T02:21:00Z'));
      final esperado = visita.createdAt.toLocal();

      expect(fechaCortaLocal(visita.createdAt),
          '${esperado.day}/${esperado.month}/${esperado.year}');
    });
  });
}

Map<String, dynamic> _jsonVisita(String createdAt) => {
      'id': 1,
      'titular': 'VISITANTE',
      'casa_destino': 'AVENIDA UNIVERSIDAD · DEPTO 11',
      'estado': 'APROBADO',
      'created_at': createdAt,
    };

Map<String, dynamic> _jsonInvitacion(String expiresAt) => {
      'id': 1,
      'tipo': 'PERSONAL',
      'titular': 'Ana Ruiz',
      'destino_id': 1,
      'conteo_usos': 0,
      'created_at': '2026-09-03T20:00:00Z',
      'expires_at': expiresAt,
    };
