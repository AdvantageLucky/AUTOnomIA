import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/invitation_viewmodel.dart';
import '../widgets/kigo_primary_button.dart';
import '../widgets/kigo_text_field.dart';

class InvitarView extends StatefulWidget {
  const InvitarView({super.key});

  @override
  State<InvitarView> createState() => _InvitarViewState();
}

class _InvitarViewState extends State<InvitarView> {
  final _telefonoCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  int? _destinoIdSeleccionado;
  bool _permiteFacial = false;
  int? _tenantIdCargado;
  String? _errorLocal;

  @override
  void dispose() {
    _telefonoCtrl.dispose();
    _nombreCtrl.dispose();
    super.dispose();
  }

  Future<void> _crear() async {
    final telefono = _telefonoCtrl.text.trim();
    final nombre = _nombreCtrl.text.trim();
    if (telefono.isEmpty || nombre.isEmpty || _destinoIdSeleccionado == null) {
      setState(() => _errorLocal = 'Completa el teléfono, el nombre y la casa destino');
      return;
    }
    setState(() => _errorLocal = null);

    final auth = context.read<AuthViewModel>();
    final vm = context.read<InvitationViewModel>();
    try {
      await vm.crear(
        tenantId: auth.centroActivo!.tenantId,
        telefono: telefono,
        nombre: nombre,
        destinoId: _destinoIdSeleccionado!,
        permiteReconocimientoFacial: _permiteFacial,
      );
      if (!mounted) return;
      _telefonoCtrl.clear();
      _nombreCtrl.clear();
      setState(() {
        _destinoIdSeleccionado = null;
        _permiteFacial = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invitación creada')),
      );
    } catch (_) {
      // el error ya quedó en vm.error, se muestra abajo
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final vm = context.watch<InvitationViewModel>();
    final tenantId = auth.centroActivo?.tenantId;

    if (tenantId != null && tenantId != _tenantIdCargado) {
      _tenantIdCargado = tenantId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        vm.cargarDestinos(tenantId);
      });
    }

    return Scaffold(
      body: tenantId == null
          ? const Center(child: Text('No tienes una membresía activa'))
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  KigoTextField(
                    controller: _nombreCtrl,
                    label: 'Nombre del invitado',
                  ),
                  const SizedBox(height: 16),
                  KigoTextField(
                    controller: _telefonoCtrl,
                    label: 'Teléfono del invitado',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: vm.destinos.any((d) => d.id == _destinoIdSeleccionado)
                        ? _destinoIdSeleccionado
                        : (vm.destinos.isNotEmpty ? vm.destinos.first.id : null),
                    decoration: const InputDecoration(labelText: 'Casa destino'),
                    items: vm.destinos.isEmpty
                        ? [
                            const DropdownMenuItem<int>(
                              value: null,
                              enabled: false,
                              child: Text('Sin casas registradas'),
                            ),
                          ]
                        : vm.destinos
                            .map((d) => DropdownMenuItem(value: d.id, child: Text(d.nombre)))
                            .toList(),
                    onChanged: vm.destinos.isEmpty
                        ? null
                        : (v) => setState(() => _destinoIdSeleccionado = v),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Permitir reconocimiento facial'),
                    subtitle: const Text('El invitado podrá entrar sin escanear su QR'),
                    value: _permiteFacial,
                    onChanged: (v) => setState(() => _permiteFacial = v),
                  ),
                  const SizedBox(height: 8),
                  if (_errorLocal != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(_errorLocal!, style: const TextStyle(color: AppTheme.error)),
                    ),
                  if (vm.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(vm.error!, style: const TextStyle(color: AppTheme.error)),
                    ),
                  KigoPrimaryButton(
                    label: 'Crear invitación',
                    loading: vm.isLoading,
                    onPressed: _crear,
                  ),
                ],
              ),
            ),
    );
  }
}
