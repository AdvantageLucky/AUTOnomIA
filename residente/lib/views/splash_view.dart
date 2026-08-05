import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../viewmodels/auth_viewmodel.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    // El AuthViewModel carga la sesión en su constructor; esperamos un frame
    // para que el estado inicial esté listo antes de navegar.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Pequeña pausa para que el ChangeNotifier termine de cargarse
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      final auth = context.read<AuthViewModel>();
      Navigator.pushReplacementNamed(
        context,
        auth.isLoggedIn ? '/dashboard' : '/login',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutBack,
          builder: (context, value, child) => Transform.scale(
            scale: value,
            child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code_scanner, size: 90, color: AppTheme.primaryOrange),
              SizedBox(height: 20),
              Text(
                'KIGO RESIDENTE',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
