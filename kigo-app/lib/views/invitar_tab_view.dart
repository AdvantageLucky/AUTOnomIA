import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/invitation_viewmodel.dart';
import '../widgets/kigo_primary_button.dart';
import '../widgets/kigo_text_field.dart';

/// Landing pública servida por el backend (ver router.go,
/// registerInvitacionLandingRoute): intenta abrir kigoapp://invitacion/<token>
/// y, si no hay app, ofrece descargarla.
String _linkInvitacion(String token) => '${AppConstants.serverOrigin}/i/$token';

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
  String? _motivoSeleccionado;
  static const _motivosFrecuentes = ['Paquete', 'Servicio', 'Visita', 'Proveedor'];
  DateTime? _expiraEl;
  int? _tenantIdCargado;
  String? _errorLocal;
  bool _recibidasCargadas = false;

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
      final token = await vm.crear(
        tenantId: auth.centroActivo!.tenantId,
        telefono: telefono,
        nombre: nombre,
        destinoId: destinoId,
        permiteReconocimientoFacial: _permiteFacial,
        motivo: _motivoSeleccionado,
        expiraEl: _expiraEl,
      );

      // El toggle "acceso frecuente por reconocimiento facial" ya no abre
      // un flujo aparte (antes vivía en la pestaña "Acceso frecuente",
      // ahora removida) -- activarlo aquí también inscribe a la persona
      // como invitado frecuente, así que puede volver a entrar por rostro
      // sin necesitar otra invitación. Un 409 significa que ya estaba
      // inscrita (p. ej. una invitación anterior a la misma persona) --
      // no es un error real, se ignora.
      if (_permiteFacial) {
        try {
          await vm.crearInvitadoFrecuente(
            tenantId: auth.centroActivo!.tenantId,
            telefono: telefono,
            nombre: nombre,
          );
        } catch (_) {
          // Ya inscrita o algún otro fallo no bloqueante -- la invitación
          // en sí ya se creó con éxito, no vale la pena interrumpir el flujo.
        }
      }

      if (!mounted) return;
      _telefonoCtrl.clear();
      _nombreCtrl.clear();
      setState(() {
        _expiraEl = null;
        _motivoSeleccionado = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Invitación creada con éxito!'),
          backgroundColor: AppTheme.success,
          duration: Duration(seconds: 2),
        ),
      );

      // Cambiamos a la pestaña de "Mis Invitaciones"
      _tabController.animateTo(1);

      if (token != null) {
        unawaited(Share.share(
          'Te invité a ${_nombreDestinoSeleccionado(vm, destinoId)} en Kigo. Abre este link: ${_linkInvitacion(token)}',
        ));
      }
    } catch (_) {
      // El error queda en vm.error
    }
  }

  String _nombreDestinoSeleccionado(InvitationViewModel vm, int destinoId) {
    final d = vm.destinos.where((d) => d.id == destinoId);
    return d.isEmpty ? 'mi casa' : d.first.nombre;
  }

  Future<void> _elegirFechaExpiracion(BuildContext context) async {
    final ahora = DateTime.now();
    final elegida = await showDatePicker(
      context: context,
      initialDate: _expiraEl ?? ahora.add(const Duration(days: 1)),
      firstDate: ahora,
      lastDate: ahora.add(const Duration(days: 365)),
      helpText: 'Vence el',
    );
    if (elegida != null) setState(() => _expiraEl = elegida);
  }

  void _compartir(String token) {
    unawaited(Share.share('Te invité a Kigo. Abre este link: ${_linkInvitacion(token)}'));
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
        vm.cargarContactos();
        vm.cargarInvitadosFrecuentes(tenantId);
      });
    }

    // Recibidas no depende de tenant/membresía: una Persona puede recibir
    // invitaciones sin pertenecer todavía a ningún centro (ver splash_view).
    if (!_recibidasCargadas) {
      _recibidasCargadas = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => vm.cargarRecibidas());
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
            // isScrollable (probado antes) obligaba a scrollear horizontal
            // para ver las 3 pestañas -- con solo 3 (ya no 4, se quitó
            // "Acceso frecuente") caben perfectamente en un solo renglón.
            // Cada pestaña envuelve su contenido en FittedBox para que el
            // texto se achique solo si el dispositivo es muy angosto, en
            // vez de truncarse o forzar scroll -- con anchos acotados
            // (isScrollable: false reparte 1/3 fijo por pestaña) FittedBox
            // sí funciona aquí (antes, con isScrollable: true, un Flexible
            // rompía el layout por constraints no acotadas).
            isScrollable: false,
            indicator: BoxDecoration(
              color: AppTheme.primaryOrange,
              borderRadius: BorderRadius.circular(AppTheme.radius),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: isDark ? AppTheme.textGrey : AppTheme.textDimmed,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
            dividerColor: Colors.transparent,
            tabs: [
              const Tab(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('Nueva Invitación'),
                ),
              ),
              Tab(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
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
              ),
              const Tab(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('Recibidas'),
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
              if (tenantId == null)
                const Center(child: Text('No tienes una membresía activa'))
              else
                _buildFormularioNuevaInvitacion(context, vm, isDark),

              // 2. MIS INVITACIONES
              if (tenantId == null)
                const Center(child: Text('No tienes una membresía activa'))
              else
                RefreshIndicator(
                  onRefresh: () async {
                    await vm.cargarInvitaciones();
                    await vm.cargarInvitadosFrecuentes(tenantId);
                  },
                  child: _buildListaInvitaciones(context, vm, isDark, tenantId),
                ),

              // 3. RECIBIDAS
              RefreshIndicator(
                onRefresh: () => vm.cargarRecibidas(),
                child: _buildListaRecibidas(context, vm, isDark),
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
        if (vm.contactos.isNotEmpty) ...[
          Text(
            'Invitar de nuevo',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: vm.contactos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final contacto = vm.contactos[i];
                return ActionChip(
                  avatar: const Icon(Icons.person_outline, size: 16),
                  label: Text(contacto.nombre.isNotEmpty ? contacto.nombre : contacto.telefono),
                  onPressed: () => setState(() {
                    _nombreCtrl.text = contacto.nombre;
                    _telefonoCtrl.text = contacto.telefono;
                    _destinoIdSeleccionado = contacto.destinoId;
                  }),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
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
                const SizedBox(height: 14),
                const Text('Motivo (opcional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _motivosFrecuentes.map((m) {
                    final seleccionado = _motivoSeleccionado == m;
                    return ChoiceChip(
                      label: Text(m),
                      selected: seleccionado,
                      selectedColor: AppTheme.primaryOrange.withValues(alpha: 0.2),
                      onSelected: (_) => setState(() => _motivoSeleccionado = seleccionado ? null : m),
                    );
                  }).toList(),
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
                              'Acceso frecuente por reconocimiento facial',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            Text(
                              'Podrá entrar por rostro en el kiosko de ahora en adelante, sin invitación cada vez. Lo puedes quitar cuando quieras desde "Mis Invitaciones".',
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
                const SizedBox(height: 14),
                InkWell(
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  onTap: () => _elegirFechaExpiracion(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.surface2Dark : AppTheme.surface2Light,
                      borderRadius: BorderRadius.circular(AppTheme.radius),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.event_outlined, color: AppTheme.primaryOrange, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Vence el',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              Text(
                                _expiraEl == null
                                    ? 'Sin fecha límite (toca para elegir una)'
                                    : '${_expiraEl!.day}/${_expiraEl!.month}/${_expiraEl!.year}',
                                style: const TextStyle(color: AppTheme.textDimmed, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        if (_expiraEl != null)
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            tooltip: 'Quitar fecha límite',
                            onPressed: () => setState(() => _expiraEl = null),
                          ),
                      ],
                    ),
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
    int tenantId,
  ) {
    if (vm.isLoading && vm.invitaciones.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final encabezadoFrecuentes = vm.invitadosFrecuentes.isEmpty
        ? const SizedBox.shrink()
        : _buildSeccionFrecuentes(context, vm, isDark, tenantId);

    if (vm.invitaciones.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          encabezadoFrecuentes,
          Padding(
            padding: const EdgeInsets.only(top: 60, left: 8, right: 8),
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
      itemCount: vm.invitaciones.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        if (i == 0) return encabezadoFrecuentes;
        final inv = vm.invitaciones[i - 1];
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
                        if (inv.expiresAt != null) ...[
                          const Text(' · ', style: TextStyle(color: AppTheme.textDimmed, fontSize: 12)),
                          Text(
                            'Vence ${inv.expiresAt!.day}/${inv.expiresAt!.month}/${inv.expiresAt!.year}',
                            style: const TextStyle(color: AppTheme.textDimmed, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (inv.vigente && inv.token != null)
                IconButton(
                  icon: const Icon(Icons.share_outlined, color: AppTheme.primaryOrange),
                  tooltip: 'Compartir link',
                  onPressed: () => _compartir(inv.token!),
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

  Widget _buildListaRecibidas(
    BuildContext context,
    InvitationViewModel vm,
    bool isDark,
  ) {
    if (vm.cargandoRecibidas && vm.recibidas.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.recibidas.isEmpty) {
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
                  child: const Icon(Icons.move_to_inbox_outlined, size: 38, color: AppTheme.textGrey),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No has recibido invitaciones',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Cuando alguien te invite a su casa, aparecerá aquí.',
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
      itemCount: vm.recibidas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final inv = vm.recibidas[i];
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
                  color: AppTheme.primaryOrange.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mail_outline_rounded, color: AppTheme.primaryOrange, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inv.casaDestino.isNotEmpty ? inv.casaDestino : inv.titular,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      inv.nombreInvita.isNotEmpty ? 'Te invitó ${inv.nombreInvita}' : 'Invitación pendiente',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textDimmed, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Sección compacta al inicio de "Mis Invitaciones": quién tiene acceso
  // frecuente por reconocimiento facial. Ya no tiene un flujo de alta
  // propio -- se activa desde el toggle de "Nueva Invitación" (ver
  // _crearInvitacion) -- solo lista y permite revocar.
  Widget _buildSeccionFrecuentes(
    BuildContext context,
    InvitationViewModel vm,
    bool isDark,
    int tenantId,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.face_retouching_natural, color: AppTheme.primaryOrange, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Acceso frecuente por rostro',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...vm.invitadosFrecuentes.map((inv) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.face_rounded, color: AppTheme.primaryOrange, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          inv.nombre.isNotEmpty ? inv.nombre : inv.telefono,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                      InkWell(
                        onTap: () => _revocarInvitadoFrecuente(context, tenantId, inv.id),
                        child: const Text(
                          'Quitar',
                          style: TextStyle(color: AppTheme.error, fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Future<void> _revocarInvitadoFrecuente(BuildContext context, int tenantId, int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Quitar acceso frecuente?'),
        content: const Text('Ya no podrá entrar por reconocimiento facial.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Quitar'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    try {
      await context.read<InvitationViewModel>().revocarInvitadoFrecuente(tenantId, id);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo quitar el acceso')),
      );
    }
  }
}
