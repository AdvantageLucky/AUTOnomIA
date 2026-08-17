import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_theme.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../../widgets/kigo_primary_button.dart';
import '../../../widgets/kigo_text_field.dart';

class StepUnirseCentro extends StatefulWidget {
  final VoidCallback onUnido;
  const StepUnirseCentro({super.key, required this.onUnido});

  @override
  State<StepUnirseCentro> createState() => _StepUnirseCentroState();
}

class _StepUnirseCentroState extends State<StepUnirseCentro> {
  final _codigoCtrl = TextEditingController();
  final _casaCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _casaCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _continuar() async {
    final auth = context.read<AuthViewModel>();
    try {
      await auth.unirseCentro(
        _codigoCtrl.text.trim(),
        _casaCtrl.text.trim(),
        _pinCtrl.text.trim(),
      );
      widget.onUnido();
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
          Text('Únete a tu centro', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          const Text('Pide el código a tu administrador si no lo tienes.'),
          const SizedBox(height: 20),
          KigoTextField(controller: _codigoCtrl, label: 'Código del centro'),
          const SizedBox(height: 12),
          KigoTextField(controller: _casaCtrl, label: 'Casa / destino'),
          const SizedBox(height: 12),
          KigoTextField(
            controller: _pinCtrl,
            label: 'PIN (4-6 dígitos)',
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 6,
          ),
          if (auth.error != null) ...[
            const SizedBox(height: 8),
            Text(auth.error!, style: const TextStyle(color: AppTheme.error, fontSize: 13)),
          ],
          const SizedBox(height: 20),
          KigoPrimaryButton(
            label: 'Unirme',
            loading: auth.isLoading,
            onPressed: _continuar,
          ),
        ],
      ),
    );
  }
}
