import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../l10n/app_localizations.dart';
import '../models/invitacion_model.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../utils/fechas.dart';

/// Detalle de una invitación que YO creé ("Mis invitaciones") -- antes la
/// fila no era tocable y no había forma de volver a ver el QR/link de una
/// invitación ya creada salvo el botón de compartir en la lista.
class InvitacionCreadaDetalleView extends StatelessWidget {
  const InvitacionCreadaDetalleView({super.key, required this.invitacion});

  final InvitacionModel invitacion;

  String get _link => '${AppConstants.serverOrigin}/i/${invitacion.token}';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inv = invitacion;

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.t(context, 'detalle_invitacion_titulo'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              inv.titular,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: inv.vigente ? AppTheme.success : AppTheme.textDimmed,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  inv.vigente
                      ? AppLocalizations.t(context, 'inv_vigente')
                      : AppLocalizations.t(context, 'no_disponible_revocada'),
                  style: TextStyle(
                    color: inv.vigente ? AppTheme.success : AppTheme.textDimmed,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (inv.vigente && inv.token != null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
                child: Center(
                  child: QrImageView(data: _link, size: 220),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.t(context, 'como_entrar_invitado'),
                textAlign: TextAlign.center,
                style: TextStyle(color: isDark ? AppTheme.textGrey : AppTheme.textDimmed, fontSize: 13),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => Share.share('${AppLocalizations.t(context, 'te_invite_a_kigo')} $_link'),
                icon: const Icon(Icons.share_outlined),
                label: Text(AppLocalizations.t(context, 'compartir_link_tooltip')),
              ),
            ] else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.cardDark : AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                ),
                child: Text(
                  AppLocalizations.t(context, 'invitacion_no_disponible_detalle'),
                  style: TextStyle(color: isDark ? AppTheme.textGrey : AppTheme.textDimmed),
                ),
              ),
            const SizedBox(height: 24),
            _buildCampo(context, AppLocalizations.t(context, 'destino_label'), '#${inv.destinoId}', isDark),
            _buildCampo(context, AppLocalizations.t(context, 'creada_el_label'),
                fechaCortaLocal(inv.createdAt), isDark),
            if (inv.expiresAt != null)
              _buildCampo(
                context,
                AppLocalizations.t(context, 'vence_prefix'),
                fechaCortaLocal(inv.expiresAt!),
                isDark,
              ),
            if (inv.maxUsos != null)
              _buildCampo(context, AppLocalizations.t(context, 'usos_label'), '${inv.conteoUsos}/${inv.maxUsos}', isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildCampo(BuildContext context, String label, String valor, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isDark ? AppTheme.textGrey : AppTheme.textDimmed, fontSize: 13)),
          Text(valor, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }
}
