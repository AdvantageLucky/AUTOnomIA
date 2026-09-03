import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
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
  final _correoCtrl = TextEditingController();
  String? _errorLocal;

  @override
  void dispose() {
    _telefonoCtrl.dispose();
    _correoCtrl.dispose();
    super.dispose();
  }

  Future<void> _continuar() async {
    final telefono = _telefonoCtrl.text.trim();
    final correo = _correoCtrl.text.trim();
    // El código se manda por correo mientras no haya un proveedor de SMS
    // real — sin correo, la solicitud no llega a ningún lado. Se pide
    // primero porque es el canal que de verdad se usa ahorita.
    if (correo.isEmpty || !correo.contains('@')) {
      setState(() => _errorLocal = AppLocalizations.t(context, 'correo_invalido'));
      return;
    }
    if (telefono.isEmpty) {
      setState(() => _errorLocal = AppLocalizations.t(context, 'telefono_requerido'));
      return;
    }
    setState(() => _errorLocal = null);

    final auth = context.read<AuthViewModel>();
    try {
      await auth.solicitarOtp(telefono, correo: correo);
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
          Text(AppLocalizations.t(context, 'correo_telefono_title'), style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(AppLocalizations.t(context, 'correo_telefono_subtitulo')),
          const SizedBox(height: 24),
          KigoTextField(
            controller: _correoCtrl,
            label: AppLocalizations.t(context, 'correo_label'),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          KigoTextField(
            controller: _telefonoCtrl,
            label: AppLocalizations.t(context, 'telefono_label'),
            keyboardType: TextInputType.phone,
            // TextInputType.phone solo cambia qué teclado sugiere el SO --
            // en varios Android igual muestra letras/símbolos, y nada
            // impedía pegar o escribir con teclado físico un valor no
            // numérico. Esto sí lo bloquea de verdad, sin importar el
            // teclado que use el dispositivo.
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          if (_errorLocal ?? auth.error case final mensaje?) ...[
            const SizedBox(height: 8),
            Text(mensaje, style: const TextStyle(color: AppTheme.error, fontSize: 13)),
          ],
          const SizedBox(height: 20),
          KigoPrimaryButton(
            label: AppLocalizations.t(context, 'continue_btn'),
            loading: auth.isLoading,
            onPressed: _continuar,
          ),
        ],
      ),
    );
  }
}
