import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/kigo_list_row.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final membresia = auth.membresia;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('Hola, ${auth.nombre}', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            if (auth.membresiaEstado == MembresiaEstado.activa && membresia != null)
              Text(
                '${membresia.centroNombre} · ${membresia.casaDestino}',
                style: const TextStyle(color: AppTheme.textDimmed),
              ),
            const SizedBox(height: 24),
            KigoListRow(
              icon: Icons.mail_outline,
              iconColor: AppTheme.blue,
              title: 'Mis invitaciones',
              subtitle: 'Ver y revocar',
              onTap: () => Navigator.pushNamed(context, '/my_invitations'),
            ),
            const Divider(),
            KigoListRow(
              icon: Icons.settings_outlined,
              title: 'Ajustes',
              onTap: () => Navigator.pushNamed(context, '/settings'),
            ),
          ],
        ),
      ),
    );
  }
}
