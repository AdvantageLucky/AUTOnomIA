import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/api_service.dart';
import '../../../theme/app_theme.dart';
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
          const SnackBar(
            content: Text('¡Tu solicitud ha sido aprobada!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (r) => false);
      } else if (auth.membresiaEstado == MembresiaEstado.rechazada) {
        setState(() => _error = 'Tu solicitud fue rechazada por la administración.');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tu solicitud sigue en revisión por la administración.'),
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo conectar al servidor');
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
        ? 'Tu solicitud en $centro ($casa) está pendiente de aprobación.'
        : 'Tu solicitud está pendiente de aprobación por el administrador.';

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
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Actualizar'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (r) => false);
            },
            child: const Text('Continuar al inicio'),
          ),
          TextButton(
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/onboarding', (r) => false);
              }
            },
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}
