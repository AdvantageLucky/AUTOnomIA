import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_theme.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../../widgets/kigo_primary_button.dart';
import '../../../widgets/kigo_text_field.dart';

class StepPerfil extends StatefulWidget {
  final VoidCallback onCompletado;
  const StepPerfil({super.key, required this.onCompletado});

  @override
  State<StepPerfil> createState() => _StepPerfilState();
}

class _StepPerfilState extends State<StepPerfil> {
  final _nombreCtrl = TextEditingController();
  final _apellidoPaternoCtrl = TextEditingController();
  final _apellidoMaternoCtrl = TextEditingController();

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoPaternoCtrl.dispose();
    _apellidoMaternoCtrl.dispose();
    super.dispose();
  }

  Future<void> _continuar() async {
    final auth = context.read<AuthViewModel>();
    try {
      await auth.completarPerfil(
        _nombreCtrl.text.trim(),
        _apellidoPaternoCtrl.text.trim(),
        _apellidoMaternoCtrl.text.trim(),
      );
      widget.onCompletado();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('¿Cómo te llamas?', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),
          KigoTextField(controller: _nombreCtrl, label: 'Nombre'),
          const SizedBox(height: 12),
          KigoTextField(controller: _apellidoPaternoCtrl, label: 'Apellido paterno'),
          const SizedBox(height: 12),
          KigoTextField(controller: _apellidoMaternoCtrl, label: 'Apellido materno (opcional)'),
          if (auth.error != null) ...[
            const SizedBox(height: 8),
            Text(auth.error!, style: const TextStyle(color: AppTheme.error, fontSize: 13)),
          ],
          const SizedBox(height: 20),
          KigoPrimaryButton(
            label: 'Continuar',
            loading: auth.isLoading,
            onPressed: _continuar,
          ),
        ],
      ),
    );
  }
}
