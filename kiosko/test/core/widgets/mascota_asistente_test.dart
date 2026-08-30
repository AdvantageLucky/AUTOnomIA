import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kigo_kiosco/core/widgets/mascota_asistente.dart';

void main() {
  testWidgets('pinta sin lanzar excepción en el estado hablando', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: MascotaAsistente(
            estado: EstadoMascota.hablando,
            pulseValue: 0.5,
            rotValue: 0.5,
          ),
        ),
      ),
    );

    expect(find.byType(MascotaAsistente), findsOneWidget);
  });

  testWidgets('los 3 estados previos siguen pintando sin lanzar excepción', (tester) async {
    for (final estado in [EstadoMascota.inactivo, EstadoMascota.escuchando, EstadoMascota.procesando]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MascotaAsistente(estado: estado, pulseValue: 0.5, rotValue: 0.5),
          ),
        ),
      );
      expect(find.byType(MascotaAsistente), findsOneWidget);
    }
  });
}
