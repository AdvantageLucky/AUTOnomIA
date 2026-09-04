import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../l10n/app_localizations.dart';
import '../models/invitacion_model.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../utils/fechas.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/invitation_viewmodel.dart';
import '../widgets/kigo_primary_button.dart';
import '../widgets/kigo_text_field.dart';
import 'invitacion_creada_detalle_view.dart';
import 'invitacion_recibida_detalle_view.dart';

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
  // Motivos que el propio residente escribió alguna vez -- se guardan en el
  // dispositivo (no son configuración del tenant, son de este residente) para
  // que no haya que volver a escribirlos en cada invitación.
  static const _keyMotivosCustom = 'motivos_custom';
  List<String> _motivosCustom = [];

  // Lista básica de groserías comunes en español -- no exhaustiva ni
  // pretende serlo (esto no es moderación de contenido en serio, es un
  // filtro simple para el motivo de una invitación). Comparación por
  // palabra completa sin acentos/mayúsculas, no por substring: así
  // "pendiente" no cae por contener "pendej-" a medias, por ejemplo.
  static const _palabrasProhibidas = {
    'puto', 'puta', 'pendejo', 'pendeja', 'verga', 'chingada', 'chingado',
    'mierda', 'cabron', 'cabrona', 'joder', 'coño', 'culero', 'culera',
    'pinche', 'maricon', 'imbecil', 'idiota', 'estupido', 'estupida',
  };

  bool _contieneGroseria(String texto) {
    final sinAcentos = texto
        .toLowerCase()
        .replaceAll(RegExp('[áà]'), 'a')
        .replaceAll(RegExp('[éè]'), 'e')
        .replaceAll(RegExp('[íì]'), 'i')
        .replaceAll(RegExp('[óò]'), 'o')
        .replaceAll(RegExp('[úù]'), 'u')
        .replaceAll('ñ', 'n');
    final palabras = sinAcentos.split(RegExp(r'[^a-z]+'));
    return palabras.any(_palabrasProhibidas.contains);
  }
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
    _cargarMotivosCustom();
  }

  Future<void> _cargarMotivosCustom() async {
    final prefs = await SharedPreferences.getInstance();
    final guardados = prefs.getStringList(_keyMotivosCustom) ?? [];
    if (mounted) setState(() => _motivosCustom = guardados);
  }

  Future<void> _agregarMotivoCustom(BuildContext context) async {
    final ctrl = TextEditingController();
    final nuevo = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        title: Text(AppLocalizations.t(ctx, 'nuevo_motivo_titulo')),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 40,
          decoration: InputDecoration(hintText: AppLocalizations.t(ctx, 'nuevo_motivo_hint')),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.t(ctx, 'cancel'))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: Text(AppLocalizations.t(ctx, 'agregar')),
          ),
        ],
      ),
    );
    final limpio = nuevo?.trim() ?? '';
    if (limpio.isEmpty || !mounted) return;

    if (_contieneGroseria(limpio)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.t(context, 'motivo_lenguaje_no_permitido'))),
      );
      return;
    }
    await _seleccionarMotivo(limpio);
  }

  /// Quita un motivo personalizado -- solo puede llamarse sobre uno de
  /// _motivosCustom (ver _menuMotivo), nunca sobre uno de los frecuentes.
  Future<void> _eliminarMotivoCustom(String motivo) async {
    setState(() {
      _motivosCustom = _motivosCustom.where((m) => m != motivo).toList();
      if (_motivoSeleccionado == motivo) _motivoSeleccionado = null;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyMotivosCustom, _motivosCustom);
  }

  /// Menú contextual de un solo motivo personalizado, anclado a donde se
  /// mantuvo presionado -- solo "Eliminar". Los frecuentes nunca llaman a
  /// esto (ver el onLongPress condicional en el build de la lista).
  Future<void> _menuMotivo(BuildContext context, Offset posicionGlobal, String motivo) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final opcion = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        posicionGlobal & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          value: 'eliminar',
          child: Row(
            children: [
              const Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 18),
              const SizedBox(width: 8),
              Text(AppLocalizations.t(context, 'eliminar_motivo_btn'), style: const TextStyle(color: AppTheme.error)),
            ],
          ),
        ),
      ],
    );
    if (opcion == 'eliminar') await _eliminarMotivoCustom(motivo);
  }

  Widget _filaMotivo(BuildContext context, String motivo, {required bool esCustom}) {
    final seleccionado = _motivoSeleccionado == motivo;
    final esUltimoFrecuente = !esCustom && motivo == _motivosFrecuentes.last && _motivosCustom.isEmpty;
    return Column(
      children: [
        GestureDetector(
          onLongPressStart: esCustom ? (details) => _menuMotivo(context, details.globalPosition, motivo) : null,
          child: InkWell(
            onTap: () => setState(() => _motivoSeleccionado = seleccionado ? null : motivo),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    seleccionado ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                    size: 18,
                    color: seleccionado ? AppTheme.primaryOrange : AppTheme.textDimmed,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      motivo,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: seleccionado ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!esUltimoFrecuente) const Divider(height: 1, indent: 14, endIndent: 14),
      ],
    );
  }

  /// Selecciona un motivo, agregándolo a la lista de motivos propios si no
  /// estaba ahí -- lo usan tanto el diálogo de "agregar motivo" como
  /// replicar una invitación pasada con un motivo que ya no aparece entre
  /// los frecuentes ni los guardados.
  Future<void> _seleccionarMotivo(String motivo) async {
    // Ni duplicar un motivo frecuente ya existente ni uno personalizado que
    // ya se había agregado antes -- comparación sin distinguir mayúsculas,
    // para que "paquete" y "Paquete" cuenten como el mismo.
    final yaExiste = [..._motivosFrecuentes, ..._motivosCustom]
        .any((m) => m.toLowerCase() == motivo.toLowerCase());

    setState(() {
      _motivoSeleccionado = motivo;
      if (!yaExiste) _motivosCustom = [..._motivosCustom, motivo];
    });
    if (!yaExiste) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_keyMotivosCustom, _motivosCustom);
    }
  }

  /// Rellena el formulario con los datos de una invitación anterior --
  /// nombre, teléfono (si el invitado ya tenía cuenta cuando se resolvió),
  /// destino y motivo. El vencimiento NO se copia: replicar una invitación
  /// de hace tiempo con esa misma fecha de vencimiento la crearía ya
  /// caducada o a punto de estarlo.
  Future<void> _replicarInvitacion(InvitacionModel inv) async {
    _nombreCtrl.text = inv.titular;
    _telefonoCtrl.text = inv.telefono ?? '';
    setState(() => _destinoIdSeleccionado = inv.destinoId);
    if (inv.motivo.isNotEmpty) {
      await _seleccionarMotivo(inv.motivo);
    } else {
      setState(() => _motivoSeleccionado = null);
    }
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
      setState(() => _errorLocal = AppLocalizations.t(context, 'completa_nombre_telefono_casa'));
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

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.t(context, 'invitacion_creada_con_exito')),
          backgroundColor: AppTheme.success,
          duration: const Duration(seconds: 2),
        ),
      );

      // Cambiamos a la pestaña de "Mis Invitaciones"
      _tabController.animateTo(1);

      if (token != null) {
        unawaited(Share.share(
          '${AppLocalizations.t(context, 'te_invite_a')} ${_nombreDestinoSeleccionado(context, vm, destinoId)}'
          ' ${AppLocalizations.t(context, 'en_kigo_abre_link')} ${_linkInvitacion(token)}',
        ));
      }
    } catch (_) {
      // El error queda en vm.error
    }
  }

  String _nombreDestinoSeleccionado(BuildContext context, InvitationViewModel vm, int destinoId) {
    final d = vm.destinos.where((d) => d.id == destinoId);
    return d.isEmpty ? AppLocalizations.t(context, 'mi_casa_fallback') : d.first.nombre;
  }

  Future<void> _elegirFechaExpiracion(BuildContext context) async {
    final ahora = DateTime.now();
    final fecha = await showDatePicker(
      context: context,
      initialDate: _expiraEl ?? ahora.add(const Duration(days: 1)),
      firstDate: ahora,
      lastDate: ahora.add(const Duration(days: 365)),
      helpText: AppLocalizations.t(context, 'vence_el'),
    );
    if (fecha == null || !context.mounted) return;

    // Sin hora exacta, un pase "vence hoy" seguía siendo válido hasta la
    // medianoche aunque el residente pensara en una hora puntual (p.ej.
    // "hasta las 6pm que se va el paquetero") -- se encadena un segundo
    // picker en vez de asumir un valor fijo.
    final horaInicial = TimeOfDay.fromDateTime(_expiraEl ?? DateTime(0, 0, 0, 20));
    final hora = await showTimePicker(
      context: context,
      initialTime: horaInicial,
      helpText: AppLocalizations.t(context, 'vence_el'),
    );
    if (!mounted) return;

    setState(() => _expiraEl = DateTime(
          fecha.year,
          fecha.month,
          fecha.day,
          hora?.hour ?? horaInicial.hour,
          hora?.minute ?? horaInicial.minute,
        ));
  }

  void _compartir(String token) {
    unawaited(Share.share(
      '${AppLocalizations.t(context, 'te_invite_a_kigo')} ${_linkInvitacion(token)}',
    ));
  }

  Future<void> _revocar(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.t(ctx, 'revocar_invitacion_titulo')),
        content: Text(AppLocalizations.t(ctx, 'revocar_invitacion_contenido')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.t(ctx, 'cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLocalizations.t(ctx, 'revoke')),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await context.read<InvitationViewModel>().revocar(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.t(context, 'inv_revoked'))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.t(context, 'revoke_invitation_error'))),
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
        // "Invitar de nuevo" ahora se arma desde vm.invitaciones (cada
        // invitación pasada, con su propio motivo) -- cargarContactos()
        // quedó sin usar aquí, ver _replicarInvitacion.
        vm.cargarInvitaciones();
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
              Tab(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(AppLocalizations.t(context, 'tab_nueva_invitacion')),
                ),
              ),
              Tab(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(AppLocalizations.t(context, 'my_invitations')),
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
              Tab(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(AppLocalizations.t(context, 'tab_recibidas')),
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
                Center(child: Text(AppLocalizations.t(context, 'no_active_membership')))
              else
                _buildFormularioNuevaInvitacion(context, vm, isDark),

              // 2. MIS INVITACIONES
              if (tenantId == null)
                Center(child: Text(AppLocalizations.t(context, 'no_active_membership')))
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
        if (vm.invitaciones.isNotEmpty) ...[
          Text(
            AppLocalizations.t(context, 'invitar_de_nuevo'),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
            ),
            // Cada invitación pasada por separado (no una por persona
            // deduplicada) para que el motivo y el destino que se usaron
            // ESA vez sean los que se replican -- no solo nombre/teléfono.
            // Limitado a las 6 más recientes: ya viene ordenado por fecha
            // desde el backend, y esta lista es un atajo, no un historial
            // completo (ese vive en la pestaña "Mis invitaciones").
            child: Column(
              children: vm.invitaciones.take(6).toList().asMap().entries.map((entry) {
                final i = entry.key;
                final inv = entry.value;
                return Column(
                  children: [
                    if (i > 0) Divider(height: 1, color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                    InkWell(
                      onTap: () => _replicarInvitacion(inv),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            const Icon(Icons.replay_rounded, color: AppTheme.primaryOrange, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    inv.titular,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    [
                                      _nombreDestinoSeleccionado(context, vm, inv.destinoId),
                                      if (inv.motivo.isNotEmpty) inv.motivo,
                                      fechaCortaLocal(inv.createdAt),
                                    ].join(' · '),
                                    style: const TextStyle(color: AppTheme.textDimmed, fontSize: 11),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
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
                // Solo puedes invitar a tu propia casa -- el backend ya lo exige
                // (CrearInvitacion rechaza cualquier otro destino_id). Antes esto
                // vivía como un campo más dentro del formulario (primero un
                // TextFormField(enabled: false), luego un bloque de solo
                // lectura) -- pero seguía leyéndose como un dato que hay que
                // revisar entre varios, cuando en realidad es el contexto fijo
                // de TODO el formulario. Va arriba, como título: "Invitar a
                // {casa}" en vez de un genérico "Datos del invitado".
                Text(
                  '${AppLocalizations.t(context, 'invitar_a_prefix')} ${destinos.isEmpty ? AppLocalizations.t(context, 'sin_casas_registradas') : destinos.firstWhere((d) => d.id == destinoValido, orElse: () => destinos.first).nombre}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 16),
                KigoTextField(
                  controller: _nombreCtrl,
                  label: AppLocalizations.t(context, 'nombre_completo_label'),
                ),
                const SizedBox(height: 14),
                KigoTextField(
                  controller: _telefonoCtrl,
                  label: AppLocalizations.t(context, 'telefono_del_invitado'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 14),
                Text(AppLocalizations.t(context, 'motivo_label'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.t(context, 'motivo_visible_admin'),
                  style: const TextStyle(color: AppTheme.textDimmed, fontSize: 11),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.surface2Dark : AppTheme.surface2Light,
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                  ),
                  child: Column(
                    children: [
                      // Los frecuentes van primero y nunca reaccionan a un
                      // long-press (no se pueden eliminar) -- solo los
                      // personalizados lo abren, para no confundir "no pasó
                      // nada" con "no había nada que borrar".
                      ..._motivosFrecuentes.map((m) => _filaMotivo(context, m, esCustom: false)),
                      ..._motivosCustom.map((m) => _filaMotivo(context, m, esCustom: true)),
                      InkWell(
                        onTap: () => _agregarMotivoCustom(context),
                        borderRadius: BorderRadius.circular(AppTheme.radius),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              const Icon(Icons.add_rounded, color: AppTheme.primaryOrange, size: 18),
                              const SizedBox(width: 10),
                              Text(
                                AppLocalizations.t(context, 'motivo_personalizado_btn'),
                                style: const TextStyle(color: AppTheme.primaryOrange, fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
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
                          children: [
                            Text(
                              AppLocalizations.t(context, 'acceso_frecuente_facial_titulo'),
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            Text(
                              AppLocalizations.t(context, 'acceso_frecuente_facial_detalle'),
                              style: const TextStyle(color: AppTheme.textDimmed, fontSize: 11),
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
                              Text(
                                AppLocalizations.t(context, 'vence_el'),
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              // Sin fechaCortaLocal: _expiraEl sale de
                              // showDatePicker, o sea que ya nacio en la zona
                              // del dispositivo. Solo las fechas que vuelven
                              // del backend llegan en UTC y necesitan convertirse.
                              Text(
                                _expiraEl == null
                                    ? AppLocalizations.t(context, 'sin_fecha_limite')
                                    : '${_expiraEl!.day}/${_expiraEl!.month}/${_expiraEl!.year}'
                                        ' ${_expiraEl!.hour.toString().padLeft(2, '0')}:${_expiraEl!.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(color: AppTheme.textDimmed, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        if (_expiraEl != null)
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            tooltip: AppLocalizations.t(context, 'quitar_fecha_limite'),
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
                  label: AppLocalizations.t(context, 'generar_pase_acceso'),
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
                Text(
                  AppLocalizations.t(context, 'sin_invitaciones_activas'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  AppLocalizations.t(context, 'crea_nuevo_pase_detalle'),
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
      itemCount: vm.invitaciones.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        if (i == 0) return encabezadoFrecuentes;
        final inv = vm.invitaciones[i - 1];
        return InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => InvitacionCreadaDetalleView(invitacion: inv)),
          ),
          child: Container(
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
                          inv.vigente
                              ? AppLocalizations.t(context, 'inv_vigente')
                              : AppLocalizations.t(context, 'no_disponible_revocada'),
                          style: TextStyle(
                            fontSize: 12,
                            color: inv.vigente ? AppTheme.success : AppTheme.textDimmed,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (inv.expiresAt != null) ...[
                          const Text(' · ', style: TextStyle(color: AppTheme.textDimmed, fontSize: 12)),
                          Text(
                            '${AppLocalizations.t(context, 'vence_prefix')} ${fechaCortaLocal(inv.expiresAt!)}',
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
                  tooltip: AppLocalizations.t(context, 'compartir_link_tooltip'),
                  onPressed: () => _compartir(inv.token!),
                ),
              if (inv.vigente)
                IconButton(
                  icon: const Icon(Icons.cancel_outlined, color: AppTheme.error),
                  tooltip: AppLocalizations.t(context, 'revocar_invitacion_tooltip'),
                  onPressed: () => _revocar(inv.id),
                ),
            ],
          ),
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
                Text(
                  AppLocalizations.t(context, 'no_recibidas_titulo'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  AppLocalizations.t(context, 'no_recibidas_detalle'),
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
      itemCount: vm.recibidas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final inv = vm.recibidas[i];
        return InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => InvitacionRecibidaDetalleView(invitacion: inv)),
          ),
          child: Container(
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
                      inv.nombreInvita.isNotEmpty
                          ? '${AppLocalizations.t(context, 'te_invito_prefix')} ${inv.nombreInvita}'
                          : AppLocalizations.t(context, 'invitacion_pendiente'),
                      style: const TextStyle(fontSize: 12, color: AppTheme.textDimmed, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppTheme.textDimmed),
            ],
          ),
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
                Text(
                  AppLocalizations.t(context, 'acceso_frecuente_por_rostro'),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
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
                        onTap: () => _resetearConfianza(context, tenantId, inv.personaId),
                        child: Text(
                          AppLocalizations.t(context, 'resetear_confianza_btn'),
                          style: const TextStyle(color: AppTheme.primaryOrange, fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 14),
                      InkWell(
                        onTap: () => _revocarInvitadoFrecuente(context, tenantId, inv.id),
                        child: Text(
                          AppLocalizations.t(context, 'quitar_btn'),
                          style: const TextStyle(color: AppTheme.error, fontSize: 12, fontWeight: FontWeight.w700),
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

  Future<void> _resetearConfianza(BuildContext context, int tenantId, int personaId) async {
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
      await context.read<InvitationViewModel>().resetearConfianza(tenantId, personaId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.t(context, 'confianza_reseteada_ok'))),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.t(context, 'no_pudo_resetear_confianza'))),
      );
    }
  }

  Future<void> _revocarInvitadoFrecuente(BuildContext context, int tenantId, int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.t(ctx, 'quitar_acceso_frecuente_titulo')),
        content: Text(AppLocalizations.t(ctx, 'quitar_acceso_frecuente_contenido')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.t(ctx, 'cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLocalizations.t(ctx, 'quitar_btn')),
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
        SnackBar(content: Text(AppLocalizations.t(context, 'no_se_pudo_quitar_acceso'))),
      );
    }
  }
}
