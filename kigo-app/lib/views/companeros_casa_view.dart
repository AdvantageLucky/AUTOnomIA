import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/companero_casa_model.dart';
import '../theme/app_theme.dart';
import '../viewmodels/companeros_casa_viewmodel.dart';

/// Lista de quienes más comparten la casa del residente en el centro activo.
class CompanerosCasaView extends StatefulWidget {
  const CompanerosCasaView({required this.tenantId, super.key});

  final int tenantId;

  @override
  State<CompanerosCasaView> createState() => _CompanerosCasaViewState();
}

class _CompanerosCasaViewState extends State<CompanerosCasaView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<CompanerosCasaViewModel>().cargar(widget.tenantId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CompanerosCasaViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compañeros de casa', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => vm.cargar(widget.tenantId),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              if (vm.casaDestino.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.cardDark : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryOrange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(AppTheme.radius),
                        ),
                        child: const Icon(Icons.home_rounded, color: AppTheme.primaryOrange, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Casa / Unidad: ${vm.casaDestino}',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${vm.companeros.length} compañero${vm.companeros.length != 1 ? 's' : ''} registrado${vm.companeros.length != 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppTheme.textGrey : AppTheme.textDimmed,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              if (vm.isLoading && vm.companeros.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (vm.error != null)
                _Aviso(
                  icono: Icons.cloud_off_rounded,
                  titulo: 'No se pudo cargar la lista',
                  detalle: vm.error!,
                  onReintentar: () => vm.cargar(widget.tenantId),
                )
              else if (vm.companeros.isEmpty)
                const _Aviso(
                  icono: Icons.people_outline_rounded,
                  titulo: 'Aún no hay nadie más registrado en tu casa',
                  detalle: 'Aquí aparecerán los demás miembros de tu hogar cuando se registren y sean aprobados.',
                )
              else
                for (final c in vm.companeros) ...[
                  _FilaCompanero(companero: c, isDark: isDark),
                  if (c != vm.companeros.last) const SizedBox(height: 10),
                ],
            ],
          ),
        ),
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
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Icon(icono, size: 52, color: AppTheme.textGrey),
          const SizedBox(height: 16),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              detalle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppTheme.textDimmed),
            ),
          ),
          if (onReintentar != null) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onReintentar,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilaCompanero extends StatelessWidget {
  const _FilaCompanero({required this.companero, required this.isDark});

  final CompaneroCasa companero;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final nombre = companero.nombreCompleto.isNotEmpty ? companero.nombreCompleto : 'Residente';
    final inicial = nombre.isNotEmpty ? nombre.substring(0, 1).toUpperCase() : 'R';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryOrange, AppTheme.brandHover],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              inicial,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Row(
                  children: const [
                    Icon(Icons.verified_rounded, size: 13, color: AppTheme.success),
                    SizedBox(width: 4),
                    Text(
                      'Residente Aprobado',
                      style: TextStyle(fontSize: 12, color: AppTheme.success, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
