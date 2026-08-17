import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';

/// Placeholder temporal — se reemplaza por el dashboard real en el plan
/// "pantallas de la app Kigo" (docs/superpowers/plans, siguiente en la
/// secuencia). Existe para que el núcleo compile y sea navegable de
/// punta a punta, incluyendo poder cerrar sesión.
class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    return Scaffold(
      appBar: AppBar(title: Text('Hola, ${auth.nombre}')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await auth.logout();
            if (context.mounted) {
              Navigator.pushNamedAndRemoveUntil(context, '/onboarding', (r) => false);
            }
          },
          child: const Text('Cerrar sesión'),
        ),
      ),
    );
  }
}
