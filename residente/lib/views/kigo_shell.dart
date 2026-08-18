import 'package:flutter/material.dart';
import 'dashboard_view.dart';
import 'invitar_view.dart';
import 'my_qr_view.dart';
import 'pending_visits_view.dart';

/// Contenedor con bottom nav de 4 destinos — Dashboard, Mi QR, Invitar,
/// Visitas pendientes. Ajustes y Mis invitaciones se llegan desde el
/// Dashboard, no ocupan slot aquí — ver spec
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
    PendingVisitsView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_outlined), activeIcon: Icon(Icons.qr_code), label: 'Mi QR'),
          BottomNavigationBarItem(icon: Icon(Icons.person_add_outlined), activeIcon: Icon(Icons.person_add), label: 'Invitar'),
          BottomNavigationBarItem(icon: Icon(Icons.how_to_reg_outlined), activeIcon: Icon(Icons.how_to_reg), label: 'Visitas'),
        ],
      ),
    );
  }
}
