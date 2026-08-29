// TEMPORAL: comprueba que el historial se recarga al entrar a su pestaña.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kigo_user/models/membresia_model.dart';
import 'package:kigo_user/models/visita_historial_model.dart';
import 'package:kigo_user/models/visita_pendiente_model.dart';
import 'package:kigo_user/theme/app_theme.dart';
import 'package:kigo_user/viewmodels/auth_viewmodel.dart';
import 'package:kigo_user/viewmodels/invitation_viewmodel.dart';
import 'package:kigo_user/viewmodels/pending_visits_viewmodel.dart';
import 'package:kigo_user/viewmodels/settings_viewmodel.dart';
import 'package:kigo_user/viewmodels/visit_history_viewmodel.dart';
import 'package:kigo_user/views/kigo_shell.dart';

class _AuthFake extends AuthViewModel {
  @override
  String get nombre => 'Ana';
  @override
  MembresiaEstado get membresiaEstado => MembresiaEstado.activa;
  @override
  MembresiaActual? get centroActivo => MembresiaActual(
      id: 1, tenantId: 7, centroNombre: 'Las Palmas',
      casaDestino: 'CASA 4', status: 'activo', pin: '42731');
  @override
  List<MembresiaActual> get membresiasActivas => [centroActivo!];
  @override
  List<MembresiaActual> get membresias => [centroActivo!];
}

class _PendingFake extends PendingVisitsViewModel {
  @override
  List<VisitaPendienteModel> get visitas => const [];
  @override
  bool get isLoading => false;
  @override
  Future<void> cargar(int tenantId) async {}
}

/// Simula el backend: al principio no hay historial; tras "aprobar" aparece
/// una visita. Cuenta cuántas veces se le pidió recargar.
class _HistoryFake extends VisitHistoryViewModel {
  int llamadas = 0;
  final List<int> tenantsPedidos = [];
  bool hayVisitaAprobada = false;
  List<VisitaHistorialModel> _v = [];

  @override
  List<VisitaHistorialModel> get visitas => _v;
  @override
  bool get isLoading => false;
  @override
  String? get error => null;

  @override
  Future<void> cargar(int tenantId) async {
    llamadas++;
    tenantsPedidos.add(tenantId);
    _v = hayVisitaAprobada
        ? [
            VisitaHistorialModel(
                id: 1, titular: 'LUIS RAMIREZ', casaDestino: 'CASA 4',
                fotoRostroUrl: '', estado: 'APROBADO',
                createdAt: DateTime(2026, 8, 28, 11, 5),
                autorizadoPorNombre: 'Ana'),
          ]
        : [];
    notifyListeners();
  }
}

ThemeData _tema() => ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppTheme.backgroundBlack,
      colorScheme: const ColorScheme.dark(primary: AppTheme.primaryOrange),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('vuelve a pedir el historial cada vez que se entra a la pestaña',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    final historial = _HistoryFake();

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthViewModel>.value(value: _AuthFake()),
        ChangeNotifierProvider<PendingVisitsViewModel>.value(value: _PendingFake()),
        ChangeNotifierProvider<VisitHistoryViewModel>.value(value: historial),
        ChangeNotifierProvider<InvitationViewModel>(create: (_) => InvitationViewModel()),
        ChangeNotifierProvider<SettingsViewModel>(create: (_) => SettingsViewModel()),
      ],
      child: MaterialApp(theme: _tema(), home: const KigoShell()),
    ));
    await tester.pump(const Duration(milliseconds: 300));

    // Carga inicial: el IndexedStack construye la pestaña al arrancar.
    expect(historial.llamadas, 1);
    expect(historial.tenantsPedidos, [7]);

    // El residente aprueba una solicitud mientras está en Inicio.
    historial.hayVisitaAprobada = true;

    await tester.tap(find.text('Visitas'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Sin la recarga al entrar, aquí seguiría en 1 y la lista saldría vacía.
    expect(historial.llamadas, 2, reason: 'debe recargar al entrar');
    expect(find.text('LUIS RAMIREZ'), findsOneWidget);
    expect(find.text('Aprobada'), findsOneWidget);

    // Y otra vez al volver a entrar.
    await tester.tap(find.text('Inicio'));
    await tester.pump();
    await tester.tap(find.text('Visitas'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(historial.llamadas, 3);
  });
}
