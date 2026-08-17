import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'widgets/step_telefono.dart';
import 'widgets/step_otp.dart';
import 'widgets/step_perfil.dart';
import 'widgets/step_unirse_centro.dart';
import 'widgets/step_espera.dart';

enum _Paso { telefono, otp, perfil, unirseCentro, espera }

/// Flujo continuo de entrada: teléfono → OTP → perfil (si es Persona
/// nueva) → unirse a centro → espera. Un solo controlador de pasos, cada
/// paso es su propio widget — ver spec 2026-08-17-kigo-app-rediseno-design.md §4.
class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  late _Paso _paso;

  @override
  void initState() {
    super.initState();
    _paso = _resolverPasoInicial();
  }

  _Paso _resolverPasoInicial() {
    final auth = context.read<AuthViewModel>();
    if (!auth.isAuthenticated) return _Paso.telefono;
    if (!auth.perfilCompleto) return _Paso.perfil;
    if (auth.membresiaEstado == MembresiaEstado.ninguna ||
        auth.membresiaEstado == MembresiaEstado.rechazada) {
      return _Paso.unirseCentro;
    }
    return _Paso.espera;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();

    if (auth.membresiaEstado == MembresiaEstado.activa) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (r) => false);
      });
    }

    return Scaffold(
      body: SafeArea(
        child: switch (_paso) {
          _Paso.telefono =>
            StepTelefono(onSolicitado: () => setState(() => _paso = _Paso.otp)),
          _Paso.otp => StepOtp(
              onVerificado: () => setState(
                () => _paso = auth.perfilCompleto ? _Paso.unirseCentro : _Paso.perfil,
              ),
            ),
          _Paso.perfil =>
            StepPerfil(onCompletado: () => setState(() => _paso = _Paso.unirseCentro)),
          _Paso.unirseCentro =>
            StepUnirseCentro(onUnido: () => setState(() => _paso = _Paso.espera)),
          _Paso.espera => const StepEspera(),
        },
      ),
    );
  }
}
