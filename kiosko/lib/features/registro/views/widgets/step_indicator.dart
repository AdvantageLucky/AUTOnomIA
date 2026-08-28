/* PROGRESO DE PASOS REUTILIZABLE */

import 'package:kigo_kiosco/core/theme/kigo_design.dart';
import 'package:flutter/material.dart';

class StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const StepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [];

    for (int index = 0; index < totalSteps; index++) {
      final bool completed = index < currentStep;
      final bool active = index == currentStep;

      children.add(
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: completed || active
                ? KigoDesign.brand
                : context.kSurface2,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: completed
                ? const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 22,
                  )
                : Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: active ? Colors.white : context.kTextSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ),
      );

      // Las líneas conectoras se reparten el espacio sobrante en vez de
      // tener un ancho fijo, para que el indicador nunca desborde sin
      // importar cuántos pasos tenga ni qué tan angosta sea la pantalla.
      if (index < totalSteps - 1) {
        children.add(
          Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              color: index < currentStep
                  ? KigoDesign.brand
                  : context.kBorder,
            ),
          ),
        );
      }
    }

    return Row(children: children);
  }
}
