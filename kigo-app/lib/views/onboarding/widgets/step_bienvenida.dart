import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/kigo_primary_button.dart';

/// Primera pantalla real que ve cualquiera que entra sin sesión guardada --
/// antes de esto, el flujo saltaba directo a un formulario de teléfono sin
/// ninguna marca ni explicación de qué es la app. Mismo lenguaje visual que
/// SplashView (ícono + wordmark), pero con contenido y una acción real.
class StepBienvenida extends StatelessWidget {
  final VoidCallback onContinuar;
  const StepBienvenida({super.key, required this.onContinuar});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          const Icon(Icons.qr_code_scanner, size: 72, color: AppTheme.primaryOrange),
          const SizedBox(height: 16),
          const Text(
            'KIGO',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 4),
          ),
          const SizedBox(height: 24),
          Text(
            'Tu acceso, sin filas',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Comparte tu QR, recibe invitados y entra a tu comunidad sin esperar en la caseta.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const Spacer(),
          KigoPrimaryButton(label: 'Continuar', onPressed: onContinuar),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
