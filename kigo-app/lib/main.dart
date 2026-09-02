import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'services/deep_link_servicio.dart';
import 'theme/app_theme.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/companeros_casa_viewmodel.dart';
import 'viewmodels/invitation_viewmodel.dart';
import 'viewmodels/pending_visits_viewmodel.dart';
import 'viewmodels/settings_viewmodel.dart';
import 'viewmodels/visit_history_viewmodel.dart';

import 'views/kigo_shell.dart';
import 'views/onboarding/onboarding_view.dart';
import 'views/settings_view.dart';
import 'views/splash_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Sin argumentos: en Android basta con google-services.json, ya procesado
  // por el plugin de Gradle — no hace falta firebase_options.dart (eso solo
  // es necesario para web o multi-plataforma explícita).
  await Firebase.initializeApp();
  DeepLinkServicio().iniciar();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel(), lazy: false),
        ChangeNotifierProvider(create: (_) => SettingsViewModel()),
        ChangeNotifierProvider(create: (_) => InvitationViewModel()),
        ChangeNotifierProvider(create: (_) => PendingVisitsViewModel()),
        ChangeNotifierProvider(create: (_) => VisitHistoryViewModel()),
        ChangeNotifierProvider(create: (_) => CompanerosCasaViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  /// Se incrementa cada vez que llega una notificación push en foreground
  /// (ver PushService.iniciar) -- KigoShell lo escucha para refrescar
  /// solicitudes pendientes / historial sin esperar a que la persona
  /// cambie de pestaña. Antes el badge de "Solicitudes" solo se
  /// actualizaba al tocar esa pestaña, así que quedaba desactualizado si
  /// la solicitud se resolvía por otro medio (otro residente de la casa,
  /// el kiosko, o el sistema por vencimiento) mientras la app seguía
  /// abierta en otra pestaña.
  static final notificationTick = ValueNotifier<int>(0);

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
        '/settings': (context) => const SettingsView(),
      },
    );
  }
}
