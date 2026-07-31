import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme/app_theme.dart';
import '../viewmodels/invitation_viewmodel.dart';
import '../models/invitation_model.dart';

class MyInvitationsView extends StatelessWidget {
  const MyInvitationsView({super.key});

  void _showQr(BuildContext context, InvitationModel inv) {
    final token = inv.token;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Text(
                inv.titular,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryOrange),
              ),
              const SizedBox(height: 4),
              Text(
                inv.tipo == 'GRUPAL' ? 'Invitación grupal' : 'Invitación personal',
                style: const TextStyle(color: AppTheme.textGrey, fontSize: 13),
              ),
              const SizedBox(height: 16),
              if (token != null)
                Container(
                  width: 220,
                  height: 220,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: QrImageView(data: token, version: QrVersions.auto, size: 200),
                )
              else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'QR no disponible.\nCrea una nueva invitación para obtener el código.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textGrey),
                  ),
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmRevoke(BuildContext context, InvitationModel inv) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Revocar invitación',
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'La invitación para "${inv.titular}" quedará inválida. ¿Continuar?',
          style: const TextStyle(color: AppTheme.textGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: AppTheme.textGrey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final ok = await context.read<InvitationViewModel>().revokeInvitation(inv.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok ? 'Invitación revocada' : 'Error al revocar'),
                    backgroundColor: ok ? null : Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text('Revocar', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<InvitationViewModel>();
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MIS INVITACIONES'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.primaryOrange),
            tooltip: 'Actualizar',
            onPressed: () => vm.fetchInvitations(),
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(16),
          child: _buildBody(context, vm, isDark),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, InvitationViewModel vm, bool isDark) {
    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryOrange));
    }
    if (vm.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_outlined, size: 48, color: AppTheme.textGrey),
            const SizedBox(height: 12),
            Text(vm.error!, style: const TextStyle(color: AppTheme.textGrey)),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => vm.fetchInvitations(),
              child: const Text('Reintentar', style: TextStyle(color: AppTheme.primaryOrange)),
            ),
          ],
        ),
      );
    }
    if (vm.invitations.isEmpty) {
      return const Center(
        child: Text('No tienes invitaciones activas.', style: TextStyle(color: AppTheme.textGrey, fontSize: 16)),
      );
    }
    return ListView.builder(
      itemCount: vm.invitations.length,
      itemBuilder: (context, index) {
        final item = vm.invitations[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Icon(
              item.tipo == 'GRUPAL' ? Icons.group_outlined : Icons.person_outlined,
              size: 36,
              color: AppTheme.primaryOrange,
            ),
            title: Text(
              item.titular,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            subtitle: Text(
              _subtitle(item),
              style: const TextStyle(color: AppTheme.textGrey, fontSize: 12),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.qr_code_2,
                    color: item.token != null
                        ? AppTheme.primaryOrange
                        : (isDark ? AppTheme.textGrey : Colors.black38),
                  ),
                  tooltip: 'Ver QR',
                  onPressed: () => _showQr(context, item),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  tooltip: 'Revocar',
                  onPressed: () => _confirmRevoke(context, item),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _subtitle(InvitationModel item) {
    final parts = <String>[];
    parts.add(item.tipo == 'GRUPAL' ? 'Grupal' : 'Personal');
    parts.add('${item.conteoUsos} uso${item.conteoUsos != 1 ? 's' : ''}');
    if (item.maxUsos != null) parts.add('máx. ${item.maxUsos}');
    if (item.expiresAt != null) {
      final e = item.expiresAt!;
      parts.add('vence ${e.day}/${e.month}/${e.year}');
    }
    return parts.join(' · ');
  }
}
