/* TARJETA DE OPCIÓN DE REGISTRO */
import 'package:kigo_kiosco/core/theme/kigo_design.dart';
import 'package:flutter/material.dart';
import 'package:kigo_kiosco/features/welcome/models/register_option_model.dart';

class RegisterOptionCard extends StatelessWidget {
  final RegisterOptionModel option;
  final bool isSelected;
  final VoidCallback onTap;

  const RegisterOptionCard({
    super.key,
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color orange = const Color(0xFFFF542F);
    final Color orangeLight = const Color(0xFFFF714D);
    final Color gray = KigoDesign.surface2;
    final Color iconGray = const Color(0xFF3A2420);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: double.infinity,
        height: 126,
        decoration: BoxDecoration(
          color: isSelected ? orange : gray,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -18,
              top: -25,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 132,
                height: 132,
                decoration: BoxDecoration(
                  color: isSelected
                      ? orangeLight.withValues(alpha: 0.55)
                      : const Color(0xFF3A2925).withValues(alpha: 0.65),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.18)
                          : iconGray,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      option.icon,
                      color: isSelected ? Colors.white : orange,
                      size: 32,
                    ),
                  ),

                  const SizedBox(width: 28),

                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          option.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          option.subtitle,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.92)
                                : const Color(0xFFA8A3A3),
                            fontSize: 17,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}