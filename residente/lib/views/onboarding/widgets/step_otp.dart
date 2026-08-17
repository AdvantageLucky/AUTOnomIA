import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_theme.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../../widgets/kigo_primary_button.dart';
import '../../../widgets/kigo_text_field.dart';

class StepOtp extends StatefulWidget {
  final VoidCallback onVerificado;
  const StepOtp({super.key, required this.onVerificado});

  @override
  State<StepOtp> createState() => _StepOtpState();
}

class _StepOtpState extends State<StepOtp> {
  final _codigoCtrl = TextEditingController();

  @override
  void dispose() {
    _codigoCtrl.dispose();
    super.dispose();
  }

  Future<void> _verificar() async {
    final auth = context.read<AuthViewModel>();
    try {
      await auth.verificarOtp(_codigoCtrl.text.trim());
      widget.onVerificado();
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
          Text('Código de verificación', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text('Lo mandamos a ${auth.telefono}.'),
          const SizedBox(height: 24),
          KigoTextField(
            controller: _codigoCtrl,
            label: 'Código de 6 dígitos',
            keyboardType: TextInputType.number,
            maxLength: 6,
          ),
          if (auth.error != null) ...[
            const SizedBox(height: 8),
            Text(auth.error!, style: const TextStyle(color: AppTheme.error, fontSize: 13)),
          ],
          const SizedBox(height: 20),
          KigoPrimaryButton(
            label: 'Verificar',
            loading: auth.isLoading,
            onPressed: _verificar,
          ),
        ],
      ),
    );
  }
}
