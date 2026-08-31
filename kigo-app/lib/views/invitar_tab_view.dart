import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/invitation_viewmodel.dart';
import '../widgets/kigo_primary_button.dart';
import '../widgets/kigo_text_field.dart';

/// Pestaña unificada de Invitar: integra la creación de un nuevo pase de
/// acceso y el listado/gestión de invitaciones vigentes y revocadas.
class InvitarTabView extends StatefulWidget {
  const InvitarTabView({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  State<InvitarTabView> createState() => _InvitarTabViewState();
}

class _InvitarTabViewState extends State<InvitarTabView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Formulario de nueva invitación
  final _telefonoCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  int? _destinoIdSeleccionado;
  bool _permiteFacial = true;
  int? _tenantIdCargado;
  String? _errorLocal;

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
    _telefonoCtrl.dispose();
    _nombreCtrl.dispose();
    super.dispose();
  }

  Future<void> _crearInvitacion() async {
    final telefono = _telefonoCtrl.text.trim();
    final nombre = _nombreCtrl.text.trim();
    final vm = context.read<InvitationViewModel>();

    final destinoId = _destinoIdSeleccionado ??
        (vm.destinos.isNotEmpty ? vm.destinos.first.id : null);

    if (nombre.isEmpty || telefono.isEmpty || destinoId == null) {
      setState(() => _errorLocal = 'Completa el nombre, teléfono y casa destino');
      return;
    }
    setState(() => _errorLocal = null);

    final auth = context.read<AuthViewModel>();
    try {
      await vm.crear(
        tenantId: auth.centroActivo!.tenantId,
        telefono: telefono,
        nombre: nombre,
        destinoId: destinoId,
        permiteReconocimientoFacial: _permiteFacial,
      );

      if (!mounted) return;
      _telefonoCtrl.clear();
      _nombreCtrl.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Invitación creada con éxito!'),
          backgroundColor: AppTheme.success,
          duration: Duration(seconds: 2),
        ),
      );

      // Cambiamos a la pestaña de "Mis Invitaciones"
      _tabController.animateTo(1);
    } catch (_) {
      // El error queda en vm.error
    }
  }

  Future<void> _revocar(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Revocar invitación?'),
        content: const Text('El invitado ya no podrá ingresar al fraccionamiento con este pase.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Revocar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await context.read<InvitationViewModel>().revocar(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invitación revocada')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo revocar la invitación')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final vm = context.watch<InvitationViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tenantId = auth.centroActivo?.tenantId;

    if (tenantId != null && tenantId != _tenantIdCargado) {
      _tenantIdCargado = tenantId;
      _destinoIdSeleccionado = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        vm.cargarDestinos(tenantId);
        vm.cargarInvitaciones();
      });
    }

    if (tenantId == null) {
      return const Center(child: Text('No tienes una membresía activa'));
    }

    final vigentesCount = vm.invitaciones.where((i) => i.vigente).length;

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
              const Tab(text: 'Nueva Invitación'),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Mis Invitaciones'),
                    if (vigentesCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$vigentesCount',
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
            ],
          ),
        ),

        // Contenido de las sub-pestañas
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // 1. NUEVA INVITACIÓN
              _buildFormularioNuevaInvitacion(context, vm, isDark),

              // 2. MIS INVITACIONES
              RefreshIndicator(
                onRefresh: () => vm.cargarInvitaciones(),
                child: _buildListaInvitaciones(context, vm, isDark),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormularioNuevaInvitacion(
    BuildContext context,
    InvitationViewModel vm,
    bool isDark,
  ) {
    final destinos = vm.destinos;
    final bool destinoExiste = _destinoIdSeleccionado != null &&
        destinos.any((d) => d.id == _destinoIdSeleccionado);
    final int? destinoValido = destinoExiste
        ? _destinoIdSeleccionado
        : (destinos.isNotEmpty ? destinos.first.id : null);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Datos del Invitado',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 16),
                KigoTextField(
                  controller: _nombreCtrl,
                  label: 'Nombre completo',
                ),
                const SizedBox(height: 14),
                KigoTextField(
                  controller: _telefonoCtrl,
                  label: 'Teléfono del invitado',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  value: destinoValido,
                  decoration: const InputDecoration(labelText: 'Casa destino'),
                  items: destinos.isEmpty
                      ? [
                          const DropdownMenuItem<int>(
                            value: null,
                            enabled: false,
                            child: Text('Sin casas registradas'),
                          ),
                        ]
                      : destinos
                          .map((d) => DropdownMenuItem<int>(value: d.id, child: Text(d.nombre)))
                          .toList(),
                  onChanged: destinos.isEmpty
                      ? null
                      : (val) => setState(() => _destinoIdSeleccionado = val),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.surface2Dark : AppTheme.surface2Light,
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.face_retouching_natural, color: AppTheme.primaryOrange, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Reconocimiento facial',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            Text(
                              'Permite al invitado ingresar mediante cámara',
                              style: TextStyle(color: AppTheme.textDimmed, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _permiteFacial,
                        activeColor: AppTheme.primaryOrange,
                        onChanged: (val) => setState(() => _permiteFacial = val),
                      ),
                    ],
                  ),
                ),
                if (_errorLocal != null || vm.error != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    _errorLocal ?? vm.error ?? '',
                    style: const TextStyle(color: AppTheme.error, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 20),
                KigoPrimaryButton(
                  label: 'Generar Pase de Acceso',
                  loading: vm.isLoading,
                  onPressed: _crearInvitacion,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListaInvitaciones(
    BuildContext context,
    InvitationViewModel vm,
    bool isDark,
  ) {
    if (vm.isLoading && vm.invitaciones.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.invitaciones.isEmpty) {
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
                  child: const Icon(Icons.mail_outline_rounded, size: 38, color: AppTheme.textGrey),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Sin invitaciones activas',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Crea un nuevo pase desde la pestaña "Nueva Invitación" para autorizar la entrada de tus visitas.',
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
      itemCount: vm.invitaciones.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final inv = vm.invitaciones[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.cardDark : AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(AppTheme.radius),
            border: Border.all(
              color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (inv.vigente ? AppTheme.success : AppTheme.textDimmed).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  inv.vigente ? Icons.qr_code_rounded : Icons.block_rounded,
                  color: inv.vigente ? AppTheme.success : AppTheme.textDimmed,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inv.titular,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: inv.vigente ? AppTheme.success : AppTheme.textDimmed,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          inv.vigente ? 'Vigente' : 'No disponible / Revocada',
                          style: TextStyle(
                            fontSize: 12,
                            color: inv.vigente ? AppTheme.success : AppTheme.textDimmed,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (inv.vigente)
                IconButton(
                  icon: const Icon(Icons.cancel_outlined, color: AppTheme.error),
                  tooltip: 'Revocar invitación',
                  onPressed: () => _revocar(inv.id),
                ),
            ],
          ),
        );
      },
    );
  }
}
