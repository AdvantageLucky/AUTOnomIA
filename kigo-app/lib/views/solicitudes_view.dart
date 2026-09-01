import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/visita_historial_model.dart';
import '../theme/app_theme.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/pending_visits_viewmodel.dart';
import '../viewmodels/visit_history_viewmodel.dart';
import '../widgets/solicitud_acceso_card.dart';
import '../widgets/visita_foto.dart';
import 'visita_detalle_view.dart';

/// Pestaña unificada de Solicitudes: integra las Solicitudes pendientes de
/// autorización en tiempo real y el Historial de visitas resueltas.
class SolicitudesView extends StatefulWidget {
  const SolicitudesView({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  State<SolicitudesView> createState() => _SolicitudesViewState();
}

class _SolicitudesViewState extends State<SolicitudesView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int? _tenantIdCargado;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _responder(int tenantId, int visitaId, String estado) async {
    try {
      await context
          .read<PendingVisitsViewModel>()
          .responder(tenantId, visitaId, estado);
      if (!mounted) return;
      // Tras resolver una solicitud, refrescamos automáticamente el historial
      context.read<VisitHistoryViewModel>().cargar(tenantId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(estado == 'APROBADO' ? 'Visita autorizada' : 'Visita rechazada'),
          backgroundColor: estado == 'APROBADO' ? AppTheme.success : AppTheme.error,
          duration: const Duration(seconds: 2),
        ),
      );
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
    final pendingVM = context.watch<PendingVisitsViewModel>();
    final historyVM = context.watch<VisitHistoryViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final tenantId = auth.centroActivo?.tenantId;

    if (tenantId != null && tenantId != _tenantIdCargado) {
      _tenantIdCargado = tenantId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        pendingVM.cargar(tenantId);
        historyVM.cargar(tenantId);
      });
    }

    if (tenantId == null) {
      return const Center(child: Text('No tienes una membresía activa'));
    }

    final pendientesCount = pendingVM.visitas.length;

    return Column(
      children: [
        // TabBar personalizado estilo píldora
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.surface2Dark : AppTheme.surface2Light,
            borderRadius: BorderRadius.circular(AppTheme.radius),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: AppTheme.primaryOrange,
              borderRadius: BorderRadius.circular(AppTheme.radius),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: isDark ? AppTheme.textGrey : AppTheme.textDimmed,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            dividerColor: Colors.transparent,
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Pendientes'),
                    if (pendientesCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$pendientesCount',
                          style: const TextStyle(
                            color: AppTheme.primaryOrange,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Tab(text: 'Historial'),
            ],
          ),
        ),

        // Contenido de las sub-pestañas
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // 1. PENDIENTES
              RefreshIndicator(
                onRefresh: () async {
                  await pendingVM.cargar(tenantId);
                },
                child: _buildPendientesList(context, tenantId, pendingVM, isDark),
              ),

              // 2. HISTORIAL
              RefreshIndicator(
                onRefresh: () async {
                  await historyVM.cargar(tenantId);
                },
                child: _buildHistorialList(context, tenantId, historyVM, isDark),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPendientesList(
    BuildContext context,
    int tenantId,
    PendingVisitsViewModel vm,
    bool isDark,
  ) {
    if (vm.isLoading && vm.visitas.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48, color: AppTheme.textGrey),
              const SizedBox(height: 12),
              Text(
                'No se pudieron cargar las solicitudes',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(vm.error!, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textDimmed)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => vm.cargar(tenantId),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    if (vm.visitas.isEmpty) {
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 80, left: 24, right: 24),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: (isDark ? AppTheme.surface2Dark : AppTheme.surface2Light),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_outline_rounded, size: 38, color: AppTheme.success),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Todo al día',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                const Text(
                  'No hay visitas esperando tu autorización en este momento.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textDimmed, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: vm.visitas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, i) {
        final v = vm.visitas[i];
        return SolicitudAccesoCard(
          visita: v,
          onAprobar: () => _responder(tenantId, v.id, 'APROBADO'),
          onRechazar: () => _responder(tenantId, v.id, 'RECHAZADO'),
        );
      },
    );
  }

  Widget _buildHistorialList(
    BuildContext context,
    int tenantId,
    VisitHistoryViewModel vm,
    bool isDark,
  ) {
    if (vm.isLoading && vm.visitas.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48, color: AppTheme.textGrey),
              const SizedBox(height: 12),
              Text('No se pudo cargar el historial', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(vm.error!, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textDimmed)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => vm.cargar(tenantId),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    if (vm.visitas.isEmpty) {
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 80, left: 24, right: 24),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: (isDark ? AppTheme.surface2Dark : AppTheme.surface2Light),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.history_rounded, size: 38, color: AppTheme.textGrey),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Sin registros todavía',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Aquí aparecerá el historial de todas las visitas que hayas autorizado o rechazado.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textDimmed, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: vm.visitas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final v = vm.visitas[i];
        return _HistorialCard(visita: v, isDark: isDark);
      },
    );
  }
}

class _HistorialCard extends StatelessWidget {
  const _HistorialCard({required this.visita, required this.isDark});

  final VisitaHistorialModel visita;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final esAprobado = visita.estado.toUpperCase() == 'APROBADO';

    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radius),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VisitaDetalleView(
            titular: visita.titular,
            casaDestino: visita.casaDestino,
            fotoRostroUrl: visita.fotoRostroUrl,
            fotoDocumentoUrl: visita.fotoDocumentoUrl,
            fotoPlacaUrl: visita.fotoPlacaUrl,
            placa: visita.placa,
            tipoVisitante: visita.tipoVisitante,
            scoreIa: visita.scoreIa,
            createdAt: visita.createdAt,
            estado: visita.estado,
            autorizadoPorNombre: visita.autorizadoPorNombre,
          ),
        ),
      ),
      child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(
          color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
        ),
      ),
      child: Row(
        children: [
          // Foto / Avatar de visitante
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            child: SizedBox(
              width: 52,
              height: 52,
              child: VisitaFoto(url: visita.fotoRostroUrl, compacta: true),
            ),
          ),
          const SizedBox(width: 14),

          // Datos de la visita
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  visita.titular,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  visita.casaDestino,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppTheme.textGrey : AppTheme.textDimmed,
                  ),
                ),
                if (visita.createdAt != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    _formatearFecha(visita.createdAt!),
                    style: const TextStyle(fontSize: 11, color: AppTheme.textDimmed),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Badge de estado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: (esAprobado ? AppTheme.success : AppTheme.error).withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  esAprobado ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  size: 13,
                  color: esAprobado ? AppTheme.success : AppTheme.error,
                ),
                const SizedBox(width: 4),
                Text(
                  esAprobado ? 'Aprobado' : 'Rechazado',
                  style: TextStyle(
                    color: esAprobado ? AppTheme.success : AppTheme.error,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  String _formatearFecha(DateTime dt) {
    final dia = dt.day.toString().padLeft(2, '0');
    final mes = _meses[dt.month - 1];
    final hora = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$dia $mes · $hora:$min';
  }

  static const _meses = [
    'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
  ];
}
