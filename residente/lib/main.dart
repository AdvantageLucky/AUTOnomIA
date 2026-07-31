import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'theme/app_theme.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/invitation_viewmodel.dart';
import 'viewmodels/settings_viewmodel.dart';

import 'views/dashboard_view.dart';
import 'views/generate_qr_view.dart';
import 'views/login_view.dart';
import 'views/my_invitations_view.dart';
import 'views/settings_view.dart';
import 'views/splash_view.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => SettingsViewModel()),
        ChangeNotifierProvider(create: (_) => InvitationViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsVM = context.watch<SettingsViewModel>();

    return MaterialApp(
      title: 'Kigo Residente',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settingsVM.themeMode,

      locale: settingsVM.currentLocale,
      supportedLocales: const [
        Locale('es', ''),
        Locale('en', ''),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashView(),
        '/login': (context) => const LoginView(),
        '/dashboard': (context) => const DashboardView(),
        '/settings': (context) => const SettingsView(),
        '/generate': (context) => const GenerateQrView(),
        '/my_invitations': (context) => const MyInvitationsView(),
      },
    );
  }
}
