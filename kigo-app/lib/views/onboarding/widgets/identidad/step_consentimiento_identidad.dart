import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../widgets/kigo_primary_button.dart';

/// Aviso de privacidad antes de pedir permiso de cámara — sin esto, el
/// wizard pasaba directo de "verifica tu número" a pedir la cámara y tomar
/// fotos de la identificación oficial y del rostro sin que la persona
/// supiera qué se iba a capturar ni para qué, antes de que el diálogo del
/// sistema operativo (que solo habla de "cámara", no de identidad) apareciera.
///
/// Se muestra una sola vez, como primer sub-paso de StepIdentidad -- ver
/// spec 2026-08-17-kigo-app-rediseno-design.md §10.
class StepConsentimientoIdentidad extends StatelessWidget {
  final VoidCallback onAceptar;
  const StepConsentimientoIdentidad({super.key, required this.onAceptar});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Icon(Icons.shield_outlined, size: 56, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.t(context, 'consentimiento_identidad_titulo'),
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.t(context, 'consentimiento_identidad_cuerpo'),
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium,
          ),
          const Spacer(flex: 2),
          KigoPrimaryButton(
            label: AppLocalizations.t(context, 'consentimiento_identidad_aceptar'),
            onPressed: onAceptar,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
