import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'utils/constants.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/invitation_viewmodel.dart';
import 'views/splash_view.dart';
import 'views/login_view.dart';
import 'views/dashboard_view.dart';
import 'views/generate_qr_view.dart';
import 'views/my_invitations_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => InvitationViewModel()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashView(),
          '/login': (context) => const LoginView(),
          '/dashboard': (context) => const DashboardView(),
          '/generate': (context) => const GenerateQrView(),
          '/my_invitations': (context) => const MyInvitationsView(),
        },
      ),
    );
  }
}