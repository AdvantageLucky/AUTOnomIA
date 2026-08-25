import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/settings_viewmodel.dart';
import '../widgets/kigo_list_row.dart';
import '../widgets/kigo_primary_button.dart';
import 'join_centro_view.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  Widget _centroRow(BuildContext context, AuthViewModel auth) {
    switch (auth.membresiaEstado) {
      case MembresiaEstado.activa:
        return KigoListRow(
          icon: Icons.home_outlined,
          iconColor: AppTheme.success,
          title: auth.membresia!.centroNombre,
          subtitle: auth.membresia!.casaDestino,
        );
      case MembresiaEstado.pendiente:
        return KigoListRow(
          icon: Icons.hourglass_top_outlined,
          iconColor: AppTheme.amber,
          title: 'Solicitud pendiente de aprobación',
          subtitle: auth.membresia?.centroNombre,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const JoinCentroView()),
          ),
        );
      case MembresiaEstado.rechazada:
        return KigoListRow(
          icon: Icons.error_outline,
          iconColor: AppTheme.error,
          title: 'Solicitud rechazada',
          subtitle: 'Toca para volver a intentar',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const JoinCentroView()),
          ),
        );
      case MembresiaEstado.ninguna:
        return KigoListRow(
          icon: Icons.add_home_outlined,
          title: 'Unirme a un centro',
          subtitle: 'Solo si vas a vivir en un fraccionamiento con Kigo',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const JoinCentroView()),
          ),
        );
    }
  }

  Future<void> _cerrarSesion(BuildContext context) async {
    await context.read<AuthViewModel>().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/splash', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final settings = context.watch<SettingsViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(auth.nombreCompleto, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(auth.telefono, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 32),
            _centroRow(context, auth),
            const Divider(),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Modo oscuro'),
              value: settings.themeMode == ThemeMode.dark,
              onChanged: (v) => settings.toggleTheme(v),
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Idioma'),
              trailing: DropdownButton<String>(
                value: settings.currentLocale.languageCode,
                items: const [
                  DropdownMenuItem(value: 'es', child: Text('Español')),
                  DropdownMenuItem(value: 'en', child: Text('English')),
                ],
                onChanged: (v) {
                  if (v != null) settings.changeLanguage(v);
                },
              ),
            ),
            const SizedBox(height: 32),
            KigoPrimaryButton(
              label: 'Cerrar sesión',
              onPressed: () => _cerrarSesion(context),
            ),
          ],
        ),
      ),
    );
  }
}
