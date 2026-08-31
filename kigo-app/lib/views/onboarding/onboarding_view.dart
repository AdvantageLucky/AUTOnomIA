import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'widgets/step_bienvenida.dart';
import 'widgets/step_telefono.dart';
import 'widgets/step_otp.dart';
import 'widgets/step_identidad.dart';

enum _Paso { bienvenida, telefono, otp, identidad }

/// Flujo de entrada: teléfono → OTP → identidad (INE+rostro, si es Persona
/// nueva). Unirse a un centro NO es parte de este flujo — una Persona puede
/// usar la app (Mi QR, recibir invitaciones) sin pertenecer a ningún centro;
/// quien quiera unirse lo hace después desde Ajustes. Ver spec
/// 2026-08-17-kigo-app-rediseno-design.md §4 y §10.
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
    if (!auth.isAuthenticated) return _Paso.bienvenida;
    return _Paso.identidad;
  }

  void _irADashboard() {
    Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();

    return Scaffold(
      body: SafeArea(
        child: switch (_paso) {
          _Paso.bienvenida =>
            StepBienvenida(onContinuar: () => setState(() => _paso = _Paso.telefono)),
          _Paso.telefono =>
            StepTelefono(onSolicitado: () => setState(() => _paso = _Paso.otp)),
          _Paso.otp => StepOtp(
              onVerificado: () {
                if (auth.perfilCompleto) {
                  _irADashboard();
                } else {
                  setState(() => _paso = _Paso.identidad);
                }
              },
            ),
          _Paso.identidad => StepIdentidad(onCompletado: _irADashboard),
        },
      ),
    );
  }
}
