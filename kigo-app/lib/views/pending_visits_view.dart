import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/pending_visits_viewmodel.dart';

class PendingVisitsView extends StatefulWidget {
  const PendingVisitsView({super.key});

  @override
  State<PendingVisitsView> createState() => _PendingVisitsViewState();
}

class _PendingVisitsViewState extends State<PendingVisitsView> {
  bool _cargado = false;

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
    final tenantId = auth.membresia?.tenantId;

    if (tenantId != null && !_cargado) {
      _cargado = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        vm.cargar(tenantId);
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Visitas pendientes')),
      body: tenantId == null
          ? const Center(child: Text('No tienes una membresía activa'))
          : vm.isLoading
              ? const Center(child: CircularProgressIndicator())
              : vm.visitas.isEmpty
                  ? const Center(child: Text('No hay visitas esperando tu autorización'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(24),
                      itemCount: vm.visitas.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, i) {
                        final v = vm.visitas[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppTheme.surface2Light,
                                backgroundImage:
                                    v.fotoRostroUrl.isNotEmpty ? NetworkImage(v.fotoRostroUrl) : null,
                                child: v.fotoRostroUrl.isEmpty
                                    ? const Icon(Icons.person_outline)
                                    : null,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(v.titular, style: Theme.of(context).textTheme.bodyLarge),
                                    Text(
                                      v.casaDestino,
                                      style: const TextStyle(color: AppTheme.textDimmed, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.check_circle, color: AppTheme.success),
                                onPressed: () => _responder(tenantId, v.id, 'APROBADO'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.cancel, color: AppTheme.error),
                                onPressed: () => _responder(tenantId, v.id, 'RECHAZADO'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}
