import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../l10n/app_localizations.dart';
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
                AppLocalizations.t(context, inv.tipo == 'GRUPAL' ? 'inv_grupal_label' : 'inv_personal_label'),
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
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    AppLocalizations.t(context, 'qr_unavailable'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.textGrey),
                  ),
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.t(context, 'close')),
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
          AppLocalizations.t(context, 'revoke_title'),
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold),
        ),
        content: Text(
          '"${inv.titular}" — ${AppLocalizations.t(context, 'revoke_body')}',
          style: const TextStyle(color: AppTheme.textGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.t(context, 'cancel'), style: const TextStyle(color: AppTheme.textGrey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final ok = await context.read<InvitationViewModel>().revokeInvitation(inv.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.t(context, ok ? 'inv_revoked' : 'revoke_error')),
                    backgroundColor: ok ? null : Colors.redAccent,
                  ),
                );
              }
            },
            child: Text(AppLocalizations.t(context, 'revoke'), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
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
        title: Text(AppLocalizations.t(context, 'my_invitations_title')),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.primaryOrange),
            tooltip: AppLocalizations.t(context, 'refresh_tooltip'),
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
              child: Text(AppLocalizations.t(context, 'retry'), style: const TextStyle(color: AppTheme.primaryOrange)),
            ),
          ],
        ),
      );
    }
    if (vm.invitations.isEmpty) {
      return Center(
        child: Text(AppLocalizations.t(context, 'no_active_invitations'), style: const TextStyle(color: AppTheme.textGrey, fontSize: 16)),
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
              _subtitle(context, item),
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

  String _subtitle(BuildContext context, InvitationModel item) {
    final l = AppLocalizations.of(context);
    final parts = <String>[];
    parts.add(item.tipo == 'GRUPAL' ? l.translate('inv_type_grupal') : l.translate('inv_type_personal'));
    final useWord = item.conteoUsos != 1 ? l.translate('inv_use_plural') : l.translate('inv_use_singular');
    parts.add('${item.conteoUsos} $useWord');
    if (item.maxUsos != null) parts.add('${l.translate('inv_max_prefix')} ${item.maxUsos}');
    if (item.expiresAt != null) {
      final e = item.expiresAt!;
      parts.add('${l.translate('inv_expires_prefix')} ${e.day}/${e.month}/${e.year}');
    }
    return parts.join(' · ');
  }
}
