import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kigo_user/theme/app_theme.dart';
import 'package:kigo_user/views/onboarding/widgets/step_bienvenida.dart';

/// Smoke test: la pantalla de entrada (barrera animada + dos opciones)
/// debe renderizar sin overflow ni excepciones en ambos temas -- sin un
/// dispositivo a la mano para verla en vivo, esto es lo mínimo que confirma
/// que el layout no se rompe.
void main() {
  for (final tema in [AppTheme.lightTheme, AppTheme.darkTheme]) {
    testWidgets('StepBienvenida renderiza sin overflow (${tema.brightness})', (tester) async {
      var tocado = false;
      await tester.pumpWidget(MaterialApp(
        theme: tema,
        home: StepBienvenida(onContinuar: () => tocado = true),
      ));
      await tester.pump(const Duration(milliseconds: 250));
      expect(tester.takeException(), isNull);

      expect(find.text('Ya vivo aquí'), findsOneWidget);
      expect(find.text('Soy nuevo aquí'), findsOneWidget);

      await tester.tap(find.text('Ya vivo aquí'));
      expect(tocado, isTrue);

      // Deja correr la animación de la pluma hasta el final, sin exceptions.
      await tester.pump(const Duration(milliseconds: 900));
      expect(tester.takeException(), isNull);
    });
  }
}
