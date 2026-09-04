import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/identidad_resumen_model.dart';
import '../models/visita_historial_model.dart';
import '../theme/app_theme.dart';
import '../utils/fechas.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/identidades_confianza_viewmodel.dart';
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
      length: 3,
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
          content: Text(AppLocalizations.t(context, estado == 'APROBADO' ? 'visita_autorizada' : 'visita_rechazada')),
          backgroundColor: estado == 'APROBADO' ? AppTheme.success : AppTheme.error,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.t(context, 'visit_response_error'))),
      );
    }
  }

  Future<void> _resetearConfianza(int tenantId, IdentidadResumenModel identidad) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.t(ctx, 'resetear_confianza_titulo')),
        content: Text(AppLocalizations.t(ctx, 'resetear_confianza_contenido')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.t(ctx, 'cancel'))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLocalizations.t(ctx, 'resetear_confianza_btn')),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    try {
      await context.read<IdentidadesConfianzaViewModel>().resetear(tenantId, identidad);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.t(context, 'confianza_reseteada_ok'))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.t(context, 'no_pudo_resetear_confianza'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final pendingVM = context.watch<PendingVisitsViewModel>();
    final historyVM = context.watch<VisitHistoryViewModel>();
    final confianzaVM = context.watch<IdentidadesConfianzaViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final tenantId = auth.centroActivo?.tenantId;

    if (tenantId != null && tenantId != _tenantIdCargado) {
      _tenantIdCargado = tenantId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        pendingVM.cargar(tenantId);
        historyVM.cargar(tenantId);
        confianzaVM.cargar(tenantId);
      });
    }

    if (tenantId == null) {
      return Center(child: Text(AppLocalizations.t(context, 'no_active_membership')));
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
            // Antes de agregar la 3a pestaña ("Confianza") esto no era
            // desplazable y las tres etiquetas (con el badge de Pendientes)
            // ya no caben en un teléfono angosto -- isScrollable evita el
            // overflow sin tener que acortar los nombres de las pestañas.
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicator: BoxDecoration(
              color: AppTheme.primaryOrange,
              borderRadius: BorderRadius.circular(AppTheme.radius),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: isDark ? AppTheme.textGrey : AppTheme.textDimmed,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            labelPadding: const EdgeInsets.symmetric(horizontal: 16),
            dividerColor: Colors.transparent,
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(AppLocalizations.t(context, 'tab_pendientes')),
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
              Tab(text: AppLocalizations.t(context, 'tab_historial')),
              Tab(text: AppLocalizations.t(context, 'tab_confianza')),
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

              // 3. CONFIANZA
              RefreshIndicator(
                onRefresh: () async {
                  await confianzaVM.cargar(tenantId);
                },
                child: _buildConfianzaList(context, tenantId, confianzaVM, isDark),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Un invitado frecuente (entra por rostro/QR, sin membresía de residente)
  // nunca va a poder ver solicitudes ni historial -- mostrarle un ícono de
  // "sin conexión" y un botón "Reintentar" sugiere una falla pasajera que
  // NUNCA se va a arreglar reintentando. Este estado no tiene botón de
  // reintentar a propósito.
  Widget _buildSoloResidentesState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.home_work_outlined, size: 48, color: AppTheme.textGrey),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.t(context, 'solo_residentes_titulo'),
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              AppLocalizations.t(context, 'solo_residentes_detalle'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textDimmed),
            ),
          ],
        ),
      ),
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
    if (vm.soloResidentes) {
      return _buildSoloResidentesState(context);
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
                AppLocalizations.t(context, 'no_se_pudieron_cargar_solicitudes'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(vm.error!, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textDimmed)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => vm.cargar(tenantId),
                icon: const Icon(Icons.refresh),
                label: Text(AppLocalizations.t(context, 'retry')),
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
                Text(
                  AppLocalizations.t(context, 'todo_al_dia'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  AppLocalizations.t(context, 'sin_visitas_esperando'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textDimmed, fontSize: 13),
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
    if (vm.soloResidentes) {
      return _buildSoloResidentesState(context);
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
              Text(AppLocalizations.t(context, 'no_se_pudo_cargar_historial'), style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(vm.error!, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textDimmed)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => vm.cargar(tenantId),
                icon: const Icon(Icons.refresh),
                label: Text(AppLocalizations.t(context, 'retry')),
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
                Text(
                  AppLocalizations.t(context, 'sin_registros_todavia'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  AppLocalizations.t(context, 'aqui_aparecera_historial'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textDimmed, fontSize: 13),
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

  static const Map<String, String> _tipoVisitanteKeys = {
    'RESIDENTE': 'identidad_tipo_residente',
    'INVITADO': 'identidad_tipo_invitado',
    'VISITANTE': 'identidad_tipo_visitante',
  };

  /// Verde/ámbar/rojo según el score de confianza de la última visita.
  Color _colorScore(int pct) {
    if (pct >= 70) return Colors.green;
    if (pct >= 40) return Colors.amber.shade800;
    return Colors.red;
  }

  Widget _buildConfianzaList(
    BuildContext context,
    int tenantId,
    IdentidadesConfianzaViewModel vm,
    bool isDark,
  ) {
    if (vm.isLoading && vm.identidades.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.soloResidentes) {
      return _buildSoloResidentesState(context);
    }
    if (vm.error != null && vm.identidades.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48, color: AppTheme.textGrey),
              const SizedBox(height: 12),
              Text(vm.error!, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textDimmed)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => vm.cargar(tenantId),
                icon: const Icon(Icons.refresh),
                label: Text(AppLocalizations.t(context, 'retry')),
              ),
            ],
          ),
        ),
      );
    }
    if (vm.identidades.isEmpty) {
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
                  child: const Icon(Icons.groups_outlined, size: 38, color: AppTheme.textGrey),
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.t(context, 'identidades_sin_datos'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  AppLocalizations.t(context, 'identidades_sin_datos_sub'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textDimmed, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: vm.identidades.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final id = vm.identidades[i];
        final tipoKey = _tipoVisitanteKeys[id.tipoVisitante];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.cardDark : AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(AppTheme.radius),
            border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: isDark ? AppTheme.surface2Dark : AppTheme.surface2Light,
                backgroundImage: (id.fotoUrl != null && id.fotoUrl!.isNotEmpty) ? NetworkImage(id.fotoUrl!) : null,
                child: (id.fotoUrl == null || id.fotoUrl!.isEmpty)
                    ? const Icon(Icons.person_outline, color: AppTheme.textGrey)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            id.sinIdentificar
                                ? AppLocalizations.t(context, 'identidad_sin_identificar')
                                : id.nombre,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (tipoKey != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryOrange.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              AppLocalizations.t(context, tipoKey),
                              style: const TextStyle(color: AppTheme.primaryOrange, fontSize: 10.5, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                        if (id.scorePct != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _colorScore(id.scorePct!).withOpacity(0.14),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${id.scorePct}%',
                              style: TextStyle(color: _colorScore(id.scorePct!), fontSize: 10.5, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${id.totalVisitas} ${id.totalVisitas == 1 ? AppLocalizations.t(context, 'identidad_visita_singular') : AppLocalizations.t(context, 'identidad_visitas_plural')}'
                      ' · ${fechaCortaLocal(id.ultimaVisita)}',
                      style: const TextStyle(color: AppTheme.textDimmed, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => _resetearConfianza(tenantId, id),
                child: Text(
                  AppLocalizations.t(context, 'resetear_confianza_btn'),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                ),
              ),
            ],
          ),
        );
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
            telefono: visita.telefono,
            curp: visita.curp,
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
                    _formatearFecha(context, visita.createdAt!),
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
                  esAprobado
                      ? AppLocalizations.t(context, 'aprobado_masc')
                      : AppLocalizations.t(context, 'rechazado_masc'),
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

  /// El backend corre en UTC y serializa `created_at` con la Z al final, asi
  /// que `DateTime.parse` devuelve un DateTime en UTC. Sin `toLocal()` la
  /// tarjeta imprimia la hora UTC tal cual: una entrada de las 20:21 en el
  /// kiosko se leia "04 Sep · 02:21", seis horas adelantada y con la fecha ya
  /// cambiada de dia. Es la misma conversion que ya hacen el detalle de la
  /// visita y el historial.
  String _formatearFecha(BuildContext context, DateTime dt) {
    final local = dt.toLocal();
    final dia = local.day.toString().padLeft(2, '0');
    final esEs = AppLocalizations.of(context).locale.languageCode == 'es';
    final mes = (esEs ? _mesesEs : _mesesEn)[local.month - 1];
    final hora = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$dia $mes · $hora:$min';
  }

  static const _mesesEs = [
    'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
  ];

  static const _mesesEn = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
}
