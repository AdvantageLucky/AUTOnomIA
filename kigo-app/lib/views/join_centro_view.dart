import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'onboarding/widgets/step_espera.dart';
import 'onboarding/widgets/step_unirse_centro.dart';

/// Unirse a un centro, ahora fuera del onboarding: se llega aquí desde
/// Ajustes, en cualquier momento — no es requisito para usar la app.
class JoinCentroView extends StatefulWidget {
  const JoinCentroView({super.key});

  @override
  State<JoinCentroView> createState() => _JoinCentroViewState();
}

class _JoinCentroViewState extends State<JoinCentroView> {
  bool _recienUnido = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final mostrarEspera = _recienUnido || auth.membresiaEstado == MembresiaEstado.pendiente;

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.t(context, 'join_centro_title'))),
      body: SafeArea(
        child: mostrarEspera
            ? const StepEspera()
            : StepUnirseCentro(onUnido: () => setState(() => _recienUnido = true)),
      ),
    );
  }
}
