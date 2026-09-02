import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
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
  String? _errorLocal;

  @override
  void dispose() {
    _codigoCtrl.dispose();
    super.dispose();
  }

  Future<void> _verificar() async {
    final codigo = _codigoCtrl.text.trim();
    if (codigo.length != 6) {
      setState(() => _errorLocal = AppLocalizations.t(context, 'codigo_6_digitos'));
      return;
    }
    setState(() => _errorLocal = null);

    final auth = context.read<AuthViewModel>();
    try {
      await auth.verificarOtp(codigo);
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
          Text(AppLocalizations.t(context, 'codigo_verificacion_title'), style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text('${AppLocalizations.t(context, 'lo_mandamos_a')} ${auth.telefono}.'),
          const SizedBox(height: 24),
          KigoTextField(
            controller: _codigoCtrl,
            label: AppLocalizations.t(context, 'codigo_6_digitos_label'),
            keyboardType: TextInputType.number,
            maxLength: 6,
          ),
          if (_errorLocal ?? auth.error case final mensaje?) ...[
            const SizedBox(height: 8),
            Text(mensaje, style: const TextStyle(color: AppTheme.error, fontSize: 13)),
          ],
          const SizedBox(height: 20),
          KigoPrimaryButton(
            label: AppLocalizations.t(context, 'verificar_btn'),
            loading: auth.isLoading,
            onPressed: _verificar,
          ),
        ],
      ),
    );
  }
}
