import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import 'barrera_acceso_animada.dart';

/// Primera pantalla real que ve cualquiera que entra sin sesión guardada --
/// antes de esto, el flujo saltaba directo a un formulario de teléfono sin
/// ninguna marca ni explicación de qué es la app, y sin distinguir a quien
/// ya vive en su comunidad de quien apenas se está dando de alta.
///
/// Las dos opciones llevan al mismo teléfono+OTP (el backend resuelve solo
/// si es alta o acceso según si el teléfono ya existe, ver
/// AuthViewModel.solicitarOtp) -- la distinción aquí es de lenguaje, para
/// que la persona sepa qué está por hacer antes de escribir su teléfono.
class StepBienvenida extends StatelessWidget {
  final VoidCallback onContinuar;
  const StepBienvenida({super.key, required this.onContinuar});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(flex: 3),
          const BarreraAccesoAnimada(),
          const SizedBox(height: 28),
          Text(
            AppLocalizations.t(context, 'bienvenida_titulo'),
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.t(context, 'bienvenida_subtitulo'),
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium,
          ),
          const Spacer(flex: 4),
          ElevatedButton(
            onPressed: onContinuar,
            child: Text(AppLocalizations.t(context, 'ya_vivo_aqui_btn')),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onContinuar,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              side: BorderSide(color: Theme.of(context).colorScheme.outline),
              foregroundColor: Theme.of(context).colorScheme.onSurface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
              textStyle: const TextStyle(fontFamily: 'Unbounded', fontWeight: FontWeight.w600, fontSize: 15),
            ),
            child: Text(AppLocalizations.t(context, 'soy_nuevo_aqui_btn')),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
