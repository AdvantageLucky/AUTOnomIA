import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../viewmodels/invitation_viewmodel.dart';
import '../widgets/kigo_list_row.dart';

class MyInvitationsView extends StatefulWidget {
  const MyInvitationsView({super.key});

  @override
  State<MyInvitationsView> createState() => _MyInvitationsViewState();
}

class _MyInvitationsViewState extends State<MyInvitationsView> {
  bool _cargado = false;

  Future<void> _revocar(int id) async {
    try {
      await context.read<InvitationViewModel>().revocar(id);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo revocar la invitación')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<InvitationViewModel>();

    if (!_cargado) {
      _cargado = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<InvitationViewModel>().cargarInvitaciones();
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mis invitaciones')),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : vm.invitaciones.isEmpty
              ? const Center(child: Text('No has creado ninguna invitación'))
              : ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: vm.invitaciones.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, i) {
                    final inv = vm.invitaciones[i];
                    return KigoListRow(
                      icon: inv.vigente ? Icons.check_circle_outline : Icons.block,
                      iconColor: inv.vigente ? AppTheme.success : AppTheme.textDimmed,
                      title: inv.titular,
                      subtitle: inv.vigente ? 'Vigente' : 'Ya no está disponible',
                      trailing: inv.vigente
                          ? IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => _revocar(inv.id),
                            )
                          : null,
                    );
                  },
                ),
    );
  }
}
