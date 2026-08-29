import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/pending_visits_viewmodel.dart';
import '../widgets/solicitud_acceso_card.dart';

/// Inicio: el saludo y, debajo, lo único que pide una acción ahora mismo —
/// las solicitudes de acceso esperando respuesta. "Mis invitaciones" y
/// "Ajustes" se movieron al menú de la barra superior.
class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  int? _tenantIdCargado;

  Future<void> _responder(int tenantId, int visitaId, String estado) async {
    try {
      await context.read<PendingVisitsViewModel>().responder(tenantId, visitaId, estado);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo enviar tu respuesta')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final vm = context.watch<PendingVisitsViewModel>();
    final membresia = auth.centroActivo;
    final tenantId = membresia?.tenantId;

    if (tenantId != null && tenantId != _tenantIdCargado) {
      _tenantIdCargado = tenantId;
      WidgetsBinding.instance.addPostFrameCallback((_) => vm.cargar(tenantId));
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (tenantId != null) await vm.cargar(tenantId);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Text('Hola, ${auth.nombre}', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          if (auth.membresiaEstado == MembresiaEstado.activa && membresia != null)
            Text(
              '${membresia.centroNombre} · ${membresia.casaDestino}',
              style: const TextStyle(color: AppTheme.textDimmed),
            ),
          const SizedBox(height: 28),
          _Encabezado(cuantas: vm.visitas.length),
          const SizedBox(height: 14),
          ..._solicitudes(context, tenantId, vm),
        ],
      ),
    );
  }

  List<Widget> _solicitudes(
    BuildContext context,
    int? tenantId,
    PendingVisitsViewModel vm,
  ) {
    if (tenantId == null) {
      return const [_Vacio(texto: 'No tienes una membresía activa')];
    }
    if (vm.isLoading) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    // El error va antes que el vacío: sin esto un fallo de red se pinta como
    // "no hay solicitudes" y no hay forma de distinguirlos.
    if (vm.error != null) {
      return [
        _Vacio(texto: 'No se pudieron cargar las solicitudes: ${vm.error}'),
      ];
    }
    if (vm.visitas.isEmpty) {
      return const [_Vacio(texto: 'No hay visitas esperando tu autorización')];
    }
    return [
      for (final v in vm.visitas) ...[
        SolicitudAccesoCard(
          visita: v,
          onAprobar: () => _responder(tenantId, v.id, 'APROBADO'),
          onRechazar: () => _responder(tenantId, v.id, 'RECHAZADO'),
        ),
        const SizedBox(height: 20),
      ],
    ];
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.cuantas});

  final int cuantas;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Solicitudes de acceso',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.2),
        ),
        if (cuantas > 0) ...[
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primaryOrange,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$cuantas',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Vacio extends StatelessWidget {
  const _Vacio({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.textGrey),
        ),
      ),
    );
  }
}
