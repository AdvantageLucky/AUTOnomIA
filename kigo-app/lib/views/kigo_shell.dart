import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/invitation_viewmodel.dart';
import '../viewmodels/pending_visits_viewmodel.dart';
import '../viewmodels/visit_history_viewmodel.dart';
import 'invitar_tab_view.dart';
import 'my_qr_view.dart';
import 'solicitudes_view.dart';

/// Contenedor principal con Bottom Nav de 3 pestañas:
/// 1. Mi QR (Pantalla de bienvenida y acceso personal)
/// 2. Solicitudes (Pendientes en tiempo real + Historial de visitas)
/// 3. Invitar (Crear pases + Mis invitaciones)
class KigoShell extends StatefulWidget {
  const KigoShell({super.key});

  @override
  State<KigoShell> createState() => _KigoShellState();
}

class _KigoShellState extends State<KigoShell> {
  int _index = 0;
  int? _tenantIdAnterior;
  late final AuthViewModel _auth;

  @override
  void initState() {
    super.initState();
    _auth = context.read<AuthViewModel>();
    _tenantIdAnterior = _auth.centroActivo?.tenantId;
    _auth.addListener(_onAuthChanged);

    // Carga inicial de datos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tenantId = _auth.centroActivo?.tenantId;
      if (tenantId != null) {
        context.read<PendingVisitsViewModel>().cargar(tenantId);
      }
    });
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    final nuevo = _auth.centroActivo?.tenantId;
    if (nuevo == _tenantIdAnterior) return;
    _tenantIdAnterior = nuevo;
    if (nuevo != null) {
      context.read<PendingVisitsViewModel>().cargar(nuevo);
      context.read<VisitHistoryViewModel>().cargar(nuevo);
      context.read<InvitationViewModel>().cargarDestinos(nuevo);
      context.read<InvitationViewModel>().cargarInvitaciones();
    }
  }

  void _irA(int i) {
    setState(() => _index = i);

    final tenantId = context.read<AuthViewModel>().centroActivo?.tenantId;
    if (tenantId == null) return;

    if (i == 1) {
      context.read<PendingVisitsViewModel>().cargar(tenantId);
      context.read<VisitHistoryViewModel>().cargar(tenantId);
    } else if (i == 2) {
      context.read<InvitationViewModel>().cargarDestinos(tenantId);
      context.read<InvitationViewModel>().cargarInvitaciones();
    }
  }

  static const _titulos = [
    'Mi QR',
    'Solicitudes',
    'Invitar',
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final pendingVM = context.watch<PendingVisitsViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pendientesCount = pendingVM.visitas.length;

    final tabs = [
      MyQrView(onGoToSolicitudes: () => _irA(1)),
      const SolicitudesView(),
      const InvitarTabView(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titulos[_index],
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          // Selector de Centro (si tiene más de 1 membresía activa)
          if (auth.membresiasActivas.length > 1)
            PopupMenuButton<int>(
              icon: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.apartment_rounded, color: AppTheme.primaryOrange, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      auth.centroActivo?.centroNombre ?? 'Centro',
                      style: const TextStyle(
                        color: AppTheme.primaryOrange,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              tooltip: 'Cambiar de centro',
              onSelected: (tenantId) => auth.setCentroActivo(tenantId),
              itemBuilder: (_) => auth.membresiasActivas
                  .map((m) => PopupMenuItem(
                        value: m.tenantId,
                        child: Row(
                          children: [
                            Icon(
                              m.tenantId == auth.centroActivo?.tenantId
                                  ? Icons.check_circle_rounded
                                  : Icons.apartment_rounded,
                              color: m.tenantId == auth.centroActivo?.tenantId
                                  ? AppTheme.primaryOrange
                                  : AppTheme.textDimmed,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Text(m.centroNombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ))
                  .toList(),
            ),

          // Botón de Ajustes
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppTheme.primaryOrange),
            iconSize: 24,
            tooltip: 'Ajustes',
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _irA,
          backgroundColor: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
          indicatorColor: AppTheme.primaryOrange.withOpacity(0.18),
          height: 65,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.qr_code_2_outlined),
              selectedIcon: Icon(Icons.qr_code_2_rounded, color: AppTheme.primaryOrange),
              label: 'Mi QR',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: pendientesCount > 0,
                label: Text('$pendientesCount'),
                backgroundColor: AppTheme.primaryOrange,
                child: const Icon(Icons.mark_chat_unread_outlined),
              ),
              selectedIcon: Badge(
                isLabelVisible: pendientesCount > 0,
                label: Text('$pendientesCount'),
                backgroundColor: AppTheme.primaryOrange,
                child: const Icon(Icons.mark_chat_unread_rounded, color: AppTheme.primaryOrange),
              ),
              label: 'Solicitudes',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_add_alt_1_outlined),
              selectedIcon: Icon(Icons.person_add_alt_1_rounded, color: AppTheme.primaryOrange),
              label: 'Invitar',
            ),
          ],
        ),
      ),
    );
  }
}
