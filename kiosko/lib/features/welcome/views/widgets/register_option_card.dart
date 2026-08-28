/* TARJETA DE OPCIÓN DE REGISTRO */
import 'package:kigo_kiosco/core/theme/kigo_design.dart';
import 'package:flutter/material.dart';
import 'package:kigo_kiosco/features/welcome/models/register_option_model.dart';
import 'package:kigo_kiosco/l10n/app_localizations.dart';

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
    final Color orange = KigoDesign.brand;
    final Color orangeLight = KigoDesign.brandHover;
    final Color gray = context.kSurface2;
    // Hueco del ícono y burbuja decorativa: en oscuro son grises calientes;
    // en claro tienen que ser un tinte de marca para no volverse manchas
    // negras sobre la tarjeta blanca.
    final Color iconGray =
        context.esTemaClaro ? orange.withValues(alpha: 0.12) : context.kChipMarca;
    final Color burbuja = context.esTemaClaro
        ? orange.withValues(alpha: 0.07)
        : const Color(0xFF3A2925).withValues(alpha: 0.65);

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
                      : burbuja,
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
                          AppLocalizations.t(context, option.titleKey),
                          style: TextStyle(
                            color: isSelected ? Colors.white : context.kTextPrimary,
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
                                : context.kTextSecondary,
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