import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../l10n/app_localizations.dart';
import '../models/invitacion_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/fechas.dart';

/// Detalle de una invitación que ME hicieron ("Recibidas") -- antes la fila
/// no era tocable y no había ninguna pantalla que explicara "cómo entro con
/// esto".
///
/// La invitación recibida NUNCA trae su propio token (solo lo ve quien la
/// creó, ver InvitacionModel.token) -- quien la recibe entra mostrando su
/// PROPIO código QR personal (el mismo de la pestaña "Mi QR"): el backend ya
/// resuelve, al escanearlo en el kiosko, que esa Persona tiene una
/// invitación válida pendiente (VerificarQR + PersonaInvitadaID). Por eso
/// esta pantalla vuelve a pedir /personas/me/qr en vez de necesitar un
/// token que el backend nunca comparte con el invitado.
class InvitacionRecibidaDetalleView extends StatefulWidget {
  const InvitacionRecibidaDetalleView({super.key, required this.invitacion});

  final InvitacionRecibidaModel invitacion;

  @override
  State<InvitacionRecibidaDetalleView> createState() => _InvitacionRecibidaDetalleViewState();
}

class _InvitacionRecibidaDetalleViewState extends State<InvitacionRecibidaDetalleView> {
  String? _dato;
  String? _error;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final data = await ApiService().get('/personas/me/qr');
      if (mounted) setState(() => _dato = '${data['persona_id']}:${data['firma']}');
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = AppLocalizations.t(context, 'no_se_pudo_conectar'));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inv = widget.invitacion;

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.t(context, 'detalle_invitacion_titulo'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              inv.casaDestino.isNotEmpty ? inv.casaDestino : inv.titular,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              inv.nombreInvita.isNotEmpty
                  ? '${AppLocalizations.t(context, 'te_invito_prefix')} ${inv.nombreInvita}'
                  : AppLocalizations.t(context, 'invitacion_pendiente'),
              style: const TextStyle(color: AppTheme.textDimmed, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            if (inv.expiresAt != null) ...[
              const SizedBox(height: 4),
              Text(
                '${AppLocalizations.t(context, 'vence_prefix')} ${fechaCortaLocal(inv.expiresAt!)}',
                style: TextStyle(color: isDark ? AppTheme.textGrey : AppTheme.textDimmed, fontSize: 13),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              AppLocalizations.t(context, 'como_entrar_recibida_titulo'),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text(
              AppLocalizations.t(context, 'como_entrar_recibida_detalle'),
              style: TextStyle(color: isDark ? AppTheme.textGrey : AppTheme.textDimmed, fontSize: 13),
            ),
            const SizedBox(height: 20),
            if (_cargando)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.cardDark : AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                ),
                child: Column(
                  children: [
                    Text(_error!, style: TextStyle(color: isDark ? AppTheme.textGrey : AppTheme.textDimmed)),
                    const SizedBox(height: 12),
                    OutlinedButton(onPressed: _cargar, child: Text(AppLocalizations.t(context, 'retry'))),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
                child: Center(child: QrImageView(data: _dato ?? '', size: 220)),
              ),
          ],
        ),
      ),
    );
  }
}
