import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'theme/app_theme.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/invitation_viewmodel.dart';
import 'viewmodels/pending_visits_viewmodel.dart';
import 'viewmodels/settings_viewmodel.dart';
import 'viewmodels/visit_history_viewmodel.dart';

import 'views/kigo_shell.dart';
import 'views/my_invitations_view.dart';
import 'views/onboarding/onboarding_view.dart';
import 'views/settings_view.dart';
import 'views/splash_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Sin argumentos: en Android basta con google-services.json, ya procesado
  // por el plugin de Gradle — no hace falta firebase_options.dart (eso solo
  // es necesario para web o multi-plataforma explícita).
  await Firebase.initializeApp();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel(), lazy: false),
        ChangeNotifierProvider(create: (_) => SettingsViewModel()),
        ChangeNotifierProvider(create: (_) => InvitationViewModel()),
        ChangeNotifierProvider(create: (_) => PendingVisitsViewModel()),
        ChangeNotifierProvider(create: (_) => VisitHistoryViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    final settingsVM = context.watch<SettingsViewModel>();

    return MaterialApp(
      scaffoldMessengerKey: scaffoldMessengerKey,
      title: 'Kigo',
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
        '/onboarding': (context) => const OnboardingView(),
        '/dashboard': (context) => const KigoShell(),
        '/my_invitations': (context) => const MyInvitationsView(),
        '/settings': (context) => const SettingsView(),
      },
    );
  }
}
