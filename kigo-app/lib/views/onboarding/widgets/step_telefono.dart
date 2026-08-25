import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_theme.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../../widgets/kigo_primary_button.dart';
import '../../../widgets/kigo_text_field.dart';

class StepTelefono extends StatefulWidget {
  final VoidCallback onSolicitado;
  const StepTelefono({super.key, required this.onSolicitado});

  @override
  State<StepTelefono> createState() => _StepTelefonoState();
}

class _StepTelefonoState extends State<StepTelefono> {
  final _telefonoCtrl = TextEditingController();
  String? _errorLocal;

  @override
  void dispose() {
    _telefonoCtrl.dispose();
    super.dispose();
  }

  Future<void> _continuar() async {
    final telefono = _telefonoCtrl.text.trim();
    if (telefono.isEmpty) {
      setState(() => _errorLocal = 'Ingresa tu número de teléfono');
      return;
    }
    setState(() => _errorLocal = null);

    final auth = context.read<AuthViewModel>();
    try {
      await auth.solicitarOtp(telefono);
      widget.onSolicitado();
    } catch (_) {
      // el error ya quedó en auth.error, se muestra abajo
    }
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
          Text('Tu número', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          const Text('Te mandamos un código para verificarlo.'),
          const SizedBox(height: 24),
          KigoTextField(
            controller: _telefonoCtrl,
            label: 'Teléfono',
            keyboardType: TextInputType.phone,
          ),
          if (_errorLocal ?? auth.error case final mensaje?) ...[
            const SizedBox(height: 8),
            Text(mensaje, style: const TextStyle(color: AppTheme.error, fontSize: 13)),
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
