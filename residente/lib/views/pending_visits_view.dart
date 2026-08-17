import 'package:flutter/material.dart';

/// Placeholder temporal — se reemplaza en el plan "pantallas de la app Kigo".
class PendingVisitsView extends StatelessWidget {
  const PendingVisitsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Visitas pendientes')),
      body: const Center(child: Text('Próximamente')),
    );
  }
}
