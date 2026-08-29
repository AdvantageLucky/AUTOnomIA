import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../theme/app_theme.dart';
import '../viewmodels/invitation_viewmodel.dart';
import '../viewmodels/visit_history_viewmodel.dart';
import 'dashboard_view.dart';
import 'invitar_view.dart';
import 'my_invitations_view.dart';
import 'my_qr_view.dart';
import 'visit_history_view.dart';

/// Contenedor con bottom nav de 5 destinos — Dashboard, Mi QR, Invitar, Mis
/// invitaciones e Historial. Las solicitudes por resolver van en el
/// Dashboard, que es la primera pantalla; el historial es consulta, no
/// acción. "Mis invitaciones" queda pegada a "Invitar" porque es el
/// seguimiento de lo que se crea ahí. Ajustes es lo único que no ocupa
/// slot: vive en la barra superior — ver spec
/// 2026-08-17-kigo-app-rediseno-design.md §6.
class KigoShell extends StatefulWidget {
  const KigoShell({super.key});

  @override
  State<KigoShell> createState() => _KigoShellState();
}

class _KigoShellState extends State<KigoShell> {
  int _index = 0;

  static const _tabs = [
    DashboardView(),
    MyQrView(),
    InvitarView(),
    MyInvitationsView(),
    VisitHistoryView(),
  ];

  // El AppBar es del shell y no de cada pestaña, para que el botón de la
  // derecha no cambie de sitio al moverse entre ellas.
  static const _titulos = [
    'Inicio',
    'Mi QR',
    'Invitar',
    'Mis invitaciones',
    'Historial de visitas',
  ];

  static const _indiceInvitaciones = 3;
  static const _indiceHistorial = 4;

  void _irA(int i) {
    setState(() => _index = i);

    // El IndexedStack construye las cinco pestañas al arrancar y las mantiene
    // vivas, así que el historial se cargaría una sola vez —vacío— y no se
    // enteraría de las solicitudes que resolviste después. Se recarga cada vez
    // que se entra, y por lo mismo las invitaciones: si no, no aparecerían las
    // que acabas de crear en la pestaña de al lado.
    if (i == _indiceHistorial) {
      final tenantId = context.read<AuthViewModel>().membresia?.tenantId;
      if (tenantId != null) {
        context.read<VisitHistoryViewModel>().cargar(tenantId);
      }
    }
    if (i == _indiceInvitaciones) {
      context.read<InvitationViewModel>().cargarInvitaciones();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titulos[_index]),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppTheme.primaryOrange),
            // 24 es el tamaño con el que BottomNavigationBar dibuja sus
            // iconos, para que el de arriba pese lo mismo que los de abajo.
            iconSize: 24,
            tooltip: 'Ajustes',
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: _irA,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_outlined), activeIcon: Icon(Icons.qr_code), label: 'Mi QR'),
          BottomNavigationBarItem(icon: Icon(Icons.person_add_outlined), activeIcon: Icon(Icons.person_add), label: 'Invitar'),
          BottomNavigationBarItem(icon: Icon(Icons.mail_outline), activeIcon: Icon(Icons.mail), label: 'Invitaciones'),
          // history y no how_to_reg: el "aprobar" que sugeria ese icono ahora
          // vive en Inicio, aqui solo se consulta lo que ya paso.
          BottomNavigationBarItem(icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history), label: 'Visitas'),
        ],
      ),
    );
  }
}
