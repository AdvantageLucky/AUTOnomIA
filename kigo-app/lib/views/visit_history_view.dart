import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/visita_historial_model.dart';
import '../theme/app_theme.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/visit_history_viewmodel.dart';
import '../widgets/visita_foto.dart';

/// Historial de los visitantes que el residente aprobó desde la app. Lo
/// rechazado, lo que sigue pendiente y lo que resolvió el vigilante desde el
/// dashboard no entran: el backend ya los filtra. Las solicitudes por resolver
/// viven en Inicio, con sus botones de aprobar y rechazar.
class VisitHistoryView extends StatefulWidget {
  const VisitHistoryView({super.key});

  @override
  State<VisitHistoryView> createState() => _VisitHistoryViewState();
}

class _VisitHistoryViewState extends State<VisitHistoryView> {
  bool _pedidaLaPrimera = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final vm = context.watch<VisitHistoryViewModel>();
    final tenantId = auth.membresia?.tenantId;

    // Solo la carga inicial. Las recargas al volver a esta pestaña las dispara
    // el shell: dentro del IndexedStack esta vista se construye al arrancar la
    // app y no se entera de que la volviste a mirar.
    if (tenantId != null && !_pedidaLaPrimera) {
      _pedidaLaPrimera = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => vm.cargar(tenantId));
    }

    if (tenantId == null) {
      return const Center(child: Text('No tienes una membresía activa'));
    }
    if (vm.isLoading && vm.visitas.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // El RefreshIndicator envuelve también los estados vacío y de error: si
    // solo cubriera la lista, quedarse sin resultados dejaría la pantalla sin
    // ninguna forma de reintentar.
    return RefreshIndicator(
      onRefresh: () => vm.cargar(tenantId),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          if (vm.error != null)
            _Aviso(
              icono: Icons.cloud_off_rounded,
              titulo: 'No se pudo cargar el historial',
              detalle: vm.error!,
              onReintentar: () => vm.cargar(tenantId),
            )
          else if (vm.visitas.isEmpty)
            const _Aviso(
              icono: Icons.history_rounded,
              titulo: 'Todavía no has aprobado ninguna visita',
              detalle: 'Aquí aparecerán los visitantes que dejes entrar desde Inicio.',
            )
          else
            for (final v in vm.visitas) ...[
              _FilaHistorial(visita: v),
              if (v != vm.visitas.last) const Divider(height: 24),
            ],
        ],
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({
    required this.icono,
    required this.titulo,
    required this.detalle,
    this.onReintentar,
  });

  final IconData icono;
  final String titulo;
  final String detalle;
  final VoidCallback? onReintentar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: [
          Icon(icono, size: 44, color: AppTheme.textGrey),
          const SizedBox(height: 14),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            detalle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppTheme.textGrey),
          ),
          if (onReintentar != null) ...[
            const SizedBox(height: 18),
            OutlinedButton(onPressed: onReintentar, child: const Text('Reintentar')),
          ],
        ],
      ),
    );
  }
}

class _FilaHistorial extends StatelessWidget {
  const _FilaHistorial({required this.visita});

  final VisitaHistorialModel visita;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tenue = isDark ? AppTheme.textDimmed : const Color(0xFF8A8BA8);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 54,
          height: 54,
          child: VisitaFoto(
            url: visita.fotoRostroUrl,
            radio: BorderRadius.circular(AppTheme.radius),
            compacta: true,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                visita.titular.isEmpty ? 'Visitante' : visita.titular,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(_fecha(visita.createdAt), style: TextStyle(fontSize: 12, color: tenue)),
              if (visita.autorizadoPorNombre.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  'Por ${visita.autorizadoPorNombre}',
                  style: TextStyle(fontSize: 12, color: tenue),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 10),
        _EstadoChip(estado: visita.estado),
      ],
    );
  }

  /// dd/mm/aaaa hh:mm en local — sin intl, que no es dependencia del proyecto.
  static String _fecha(DateTime utc) {
    final d = utc.toLocal();
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(d.day)}/${dos(d.month)}/${d.year} · ${dos(d.hour)}:${dos(d.minute)}';
  }
}

class _EstadoChip extends StatelessWidget {
  const _EstadoChip({required this.estado});

  final String estado;

  @override
  Widget build(BuildContext context) {
    final (color, etiqueta) = switch (estado) {
      'APROBADO' => (AppTheme.success, 'Aprobada'),
      'RECHAZADO' => (AppTheme.error, 'Rechazada'),
      'PENDIENTE' => (AppTheme.amber, 'Pendiente'),
      'REVISION' => (AppTheme.blue, 'En revisión'),
      _ => (AppTheme.textGrey, estado.isEmpty ? '—' : estado),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        etiqueta,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
