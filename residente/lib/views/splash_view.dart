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
    // Ejecutar la comprobación de sesión al cargar la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthViewModel>().checkSession().then((_) {
        if (mounted) {
          final auth = context.read<AuthViewModel>();
          // Navegación fluida según el estado de la sesión
          Navigator.pushReplacementNamed(
            context, 
            auth.isLoggedIn ? '/dashboard' : '/login'
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code_scanner, size: 90, color: AppTheme.primaryOrange),
              SizedBox(height: 20),
              Text(
                'KIGO USER',
                style: TextStyle(
                  fontSize: 28, 
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