import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/companero_casa_model.dart';
import '../theme/app_theme.dart';
import '../viewmodels/companeros_casa_viewmodel.dart';

/// Lista de quienes más comparten la casa del residente en el centro activo
/// — se abre desde Ajustes. A diferencia de las pestañas del KigoShell, esta
/// pantalla se abre con Navigator.push: cada apertura parte de un
/// ViewModel fresco con el tenantId vigente en ese momento, así que no
/// necesita ningún mecanismo de recarga al cambiar de centro.
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

    return Scaffold(
      appBar: AppBar(title: const Text('Compañeros de casa')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => vm.cargar(widget.tenantId),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
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
                  detalle: 'Aquí aparecerán los demás miembros de tu casa cuando se unan.',
                )
              else
                for (final c in vm.companeros) ...[
                  _FilaCompanero(companero: c),
                  if (c != vm.companeros.last) const Divider(height: 24),
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

class _FilaCompanero extends StatelessWidget {
  const _FilaCompanero({required this.companero});

  final CompaneroCasa companero;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.primaryOrange.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person_outline, color: AppTheme.primaryOrange),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                companero.nombreCompleto,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                companero.rol == 'titular' ? 'Titular' : 'Familiar',
                style: const TextStyle(fontSize: 12, color: AppTheme.textGrey),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
