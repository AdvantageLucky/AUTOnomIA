import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme/app_theme.dart';
import '../viewmodels/invitation_viewmodel.dart';
import '../models/invitation_model.dart';

class MyInvitationsView extends StatelessWidget {
  const MyInvitationsView({super.key});

  void _showQrOnly(BuildContext context, InvitationModel invitation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Text(invitation.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryOrange)),
              const SizedBox(height: 4),
              Text(invitation.company, style: const TextStyle(color: AppTheme.textGrey, fontSize: 14)),
              const SizedBox(height: 16),
              Container(
                width: 220,
                height: 220,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: QrImageView(
                      data: invitation.id,
                      version: QrVersions.auto,
                      size: 200.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CERRAR'),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final invitationVM = context.watch<InvitationViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('MIS INVITACIONES')),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(16.0),
          child: invitationVM.invitations.isEmpty
              ? const Center(
                  child: Text(
                    'No tienes invitaciones activas.',
                    style: TextStyle(color: AppTheme.textGrey, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: invitationVM.invitations.length,
                  itemBuilder: (context, index) {
                    final item = invitationVM.invitations[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const Icon(Icons.qr_code, size: 40, color: AppTheme.primaryOrange),
                        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${item.company} • Vence: ${item.time}', style: const TextStyle(color: AppTheme.textGrey)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility_outlined, color: Colors.white70),
                              onPressed: () => _showQrOnly(context, item),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () {
                                context.read<InvitationViewModel>().deleteInvitation(item.id);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}