import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_theme.dart';
import '../../../viewmodels/auth_viewmodel.dart';

class StepEspera extends StatelessWidget {
  const StepEspera({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final centro = auth.membresia?.centroNombre ?? '';
    final casa = auth.membresia?.casaDestino ?? '';
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.hourglass_top, size: 56, color: AppTheme.primaryOrange),
          const SizedBox(height: 20),
          Text(
            'Tu solicitud en $centro ($casa) está pendiente de aprobación.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () async {
              await auth.refrescarMembresia();
            },
            child: const Text('Actualizar'),
          ),
          TextButton(
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/onboarding', (r) => false);
              }
            },
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}
