/* PROGRESO DE PASOS REUTILIZABLE */

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
                ? const Color(0xFFFF542F)
                : const Color(0xFF2B2727),
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
                      color: active ? Colors.white : const Color(0xFF8A8585),
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
                  ? const Color(0xFFFF542F)
                  : const Color(0xFF3A3434),
            ),
          ),
        );
      }
    }

    return Row(children: children);
  }
}
