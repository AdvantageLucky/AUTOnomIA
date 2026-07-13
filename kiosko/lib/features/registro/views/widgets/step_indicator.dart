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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (index) {
        final bool completed = index < currentStep;
        final bool active = index == currentStep;

        return Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 54,
              height: 54,
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
                        size: 27,
                      )
                    : Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: active
                              ? Colors.white
                              : const Color(0xFF8A8585),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
            if (index < totalSteps - 1)
              Container(
                width: 54,
                height: 3,
                color: index < currentStep
                    ? const Color(0xFFFF542F)
                    : const Color(0xFF3A3434),
              ),
          ],
        );
      }),
    );
  }
}