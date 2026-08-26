import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:kigo_kiosco/core/models/kiosko_config.dart';
import 'package:kigo_kiosco/core/notifiers/kiosko_config_notifier.dart';
import 'package:kigo_kiosco/core/services/connectivity_service.dart';
import 'package:kigo_kiosco/core/services/local_cache_db.dart';
import 'package:kigo_kiosco/core/services/sync_worker.dart';
import 'package:kigo_kiosco/core/theme/kigo_design.dart';
import 'package:kigo_kiosco/features/activacion/views/activacion_view.dart';
import 'package:kigo_kiosco/features/registro/services/kiosko_servicio.dart';
import 'package:kigo_kiosco/features/welcome/viewmodels/qr_scanner_viewmodel.dart';
import 'package:kigo_kiosco/features/welcome/viewmodels/welcome_viewmodel.dart';
import 'package:kigo_kiosco/features/welcome/views/qr_scanner_view.dart';
import 'package:kigo_kiosco/features/welcome/views/welcome_view.dart';
import 'package:kigo_kiosco/l10n/app_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  _activarModoInmersivo();

  final servicio = KioskoServicio();
  final configNotifier = KioskoConfigNotifier(servicio);

  final connectivityService = ConnectivityService();
  final localCacheDb = LocalCacheDb();
  servicio.configurarOffline(connectivityService, localCacheDb);
  final syncWorker = SyncWorker(
    cache: localCacheDb,
    connectivity: connectivityService,
    refrescarSnapshot: () => _refrescarSnapshot(servicio, localCacheDb),
    reproducirRegistro: (registro) => _reproducirRegistroContraBackend(servicio, registro),
  );

  runApp(MultiProvider(
    providers: [
      Provider<KioskoServicio>.value(value: servicio),
      ChangeNotifierProvider<KioskoConfigNotifier>.value(value: configNotifier),
      ChangeNotifierProvider<ConnectivityService>.value(value: connectivityService),
    ],
    child: const KigoApp(),
  ));

  // Se inicializa después de runApp para que el splash ya sea visible
  configNotifier.inicializar();
  _iniciarModoOffline(localCacheDb, connectivityService, syncWorker);
}

/// LocalCacheDb debe abrirse antes de que ConnectivityService/SyncWorker
/// intenten usarla — por eso este orden, no porque haya una dependencia
/// circular entre los tres.
Future<void> _iniciarModoOffline(
  LocalCacheDb cache,
  ConnectivityService connectivity,
  SyncWorker syncWorker,
) async {
  await cache.iniciar();
  await connectivity.iniciar();
  await syncWorker.iniciar();
}

Future<void> _refrescarSnapshot(KioskoServicio servicio, LocalCacheDb cache) async {
  final snapshot = await servicio.obtenerSnapshot();
  await cache.reemplazarDestinos((snapshot['destinos'] as List).cast<Map<String, dynamic>>());
  await cache.reemplazarResidentes((snapshot['residentes'] as List).cast<Map<String, dynamic>>());
  await cache.reemplazarInvitaciones((snapshot['invitaciones'] as List).cast<Map<String, dynamic>>());
}

/// Reproduce un registro de visitas_queue contra el backend real. Se llama
/// solo cuando SyncWorker ya confirmó que hay red — usa los métodos
/// "reproducir*" de KioskoServicio (sin el fallback automático a cola) para
/// que un fallo de red aquí se propague tal cual y detenga el drenado, en
/// vez de tragárselo y reencolar un duplicado silenciosamente.
Future<Map<String, dynamic>> _reproducirRegistroContraBackend(
  KioskoServicio servicio,
  Map<String, dynamic> registro,
) async {
  final tipo = registro['tipo'] as String;
  final payload = jsonDecode(registro['payload_json'] as String) as Map<String, dynamic>;
  final fotoPaths = (jsonDecode(registro['foto_paths_json'] as String) as Map).cast<String, dynamic>();
  final clientId = registro['client_id'] as String;

  switch (tipo) {
    case 'visitante_nuevo':
      return servicio.reproducirVisitanteNuevo(
        titular: payload['titular'] as String? ?? '',
        curp: payload['curp'] as String? ?? '',
        casaDestino: payload['casa_destino'] as String? ?? '',
        placa: payload['placa'] as String? ?? '',
        pathFotoIne: fotoPaths['ine'] as String?,
        pathFotoRostro: fotoPaths['rostro'] as String?,
        pathFotoPlaca: fotoPaths['placa'] as String?,
        clientId: clientId,
      );
    case 'invitacion':
      try {
        return await servicio.reproducirInvitacion(
          payload['token'] as String,
          placa: payload['placa'] as String? ?? '',
          curp: payload['curp'] as String?,
          pathFotoIne: fotoPaths['ine'] as String?,
          pathFotoRostro: fotoPaths['rostro'] as String?,
          pathFotoPlaca: fotoPaths['placa'] as String?,
          clientId: clientId,
        );
      } on InvitacionInvalidaException catch (e) {
        // El token ya se consumió (posiblemente en otro kiosko offline al
        // mismo tiempo) — es un rechazo legítimo del backend, no un fallo
        // de red: SyncWorker debe marcarlo como conflicto, no reintentarlo.
        throw SyncConflictException(e.mensaje);
      }
    case 'rostro_residente':
      final embedding = (payload['embedding'] as List).cast<double>();
      return servicio.reproducirVerificacionRostro(embedding, clientId: clientId);
    default:
      throw StateError('tipo de registro offline desconocido: $tipo');
  }
}

// Oculta barra de estado y de navegación. Se vuelve a invocar en cada resume
// porque Android suele soltar el modo inmersivo al volver de segundo plano.
void _activarModoInmersivo() {
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
}

class KigoApp extends StatefulWidget {
  const KigoApp({super.key});

  @override
  State<KigoApp> createState() => _KigoAppState();
}

class _KigoAppState extends State<KigoApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _activarModoInmersivo();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<KioskoConfigNotifier>(
      builder: (context, cfg, _) {
        final esClaro = cfg.config.colorTema == KioskoColorTema.claro;
        final locale = Locale(cfg.config.idioma);

        return MaterialApp(
          title: 'Kigo',
          debugShowCheckedModeBanner: false,
          locale: locale,
          supportedLocales: const [Locale('es'), Locale('en')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: esClaro ? KigoDesign.lightTheme : KigoDesign.darkTheme,
          home: Builder(builder: (context) {
            if (cfg.cargando) return const _SplashScreen();
            if (cfg.necesitaActivacion) {
              return ActivacionView(onActivado: () => cfg.reinicializar());
            }
            return QrScannerView(
              viewModel: QrScannerViewModel(),
              onSinCodigo: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => WelcomeView(viewModel: WelcomeViewModel()),
              )),
            );
          }),
        );
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'K',
              style: TextStyle(
                color: KigoDesign.brand,
                fontSize: 72,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 32),
            CircularProgressIndicator(
              color: KigoDesign.brand,
              strokeWidth: 2.5,
            ),
          ],
        ),
      ),
    );
  }
}
