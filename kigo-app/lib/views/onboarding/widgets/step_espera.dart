import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/api_service.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/hazard_stripe.dart';
import '../../../viewmodels/auth_viewmodel.dart';

class StepEspera extends StatefulWidget {
  const StepEspera({super.key});

  @override
  State<StepEspera> createState() => _StepEsperaState();
}

class _StepEsperaState extends State<StepEspera> {
  String? _error;
  bool _cargando = false;

  Future<void> _actualizar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    final auth = context.read<AuthViewModel>();
    try {
      await auth.refrescarMembresia();
      if (!mounted) return;
      if (auth.membresiaEstado == MembresiaEstado.activa || auth.membresiasActivas.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.t(context, 'solicitud_aprobada')),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (r) => false);
      } else if (auth.membresiaEstado == MembresiaEstado.rechazada) {
        setState(() => _error = AppLocalizations.t(context, 'solicitud_rechazada'));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.t(context, 'solicitud_en_revision')),
          ),
        );
      }
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
    final auth = context.watch<AuthViewModel>();
    final pendiente = auth.membresias.where((m) => m.status == 'pendiente').firstOrNull ??
        (auth.membresias.isNotEmpty ? auth.membresias.first : null);
    final centro = pendiente?.centroNombre ?? '';
    final casa = pendiente?.casaDestino ?? '';
    final texto = centro.isNotEmpty
        ? '${AppLocalizations.t(context, 'solicitud_pendiente_en')} $centro ($casa)${AppLocalizations.t(context, 'solicitud_pendiente_sufijo')}'
        : AppLocalizations.t(context, 'solicitud_pendiente_generico');

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.hourglass_top, size: 56, color: AppTheme.primaryOrange),
          const SizedBox(height: 20),
          Text(
            texto,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppTheme.error, fontSize: 13)),
          ],
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: _cargando ? null : _actualizar,
            child: _cargando
                ? const SizedBox(
                    width: 40,
                    height: 6,
                    child: HazardStripeBar(height: 6),
                  )
                : Text(AppLocalizations.t(context, 'actualizar_btn')),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (r) => false);
            },
            child: Text(AppLocalizations.t(context, 'continuar_al_inicio')),
          ),
          TextButton(
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/onboarding', (r) => false);
              }
            },
            child: Text(AppLocalizations.t(context, 'logout_tooltip')),
          ),
        ],
      ),
    );
  }
}
