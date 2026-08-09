import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../viewmodels/registro_viewmodel.dart';
import 'registro_estado_view.dart';

class RegistroView extends StatelessWidget {
  const RegistroView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RegistroViewModel(),
      child: const _RegistroScaffold(),
    );
  }
}

class _RegistroScaffold extends StatelessWidget {
  const _RegistroScaffold();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RegistroViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de residente'),
        leading: vm.paso > 0
            ? BackButton(onPressed: () => context.read<RegistroViewModel>().retroceder())
            : const BackButton(),
      ),
      body: Column(
        children: [
          _StepIndicator(paso: vm.paso),
          Expanded(child: _PasoActual(vm: vm)),
        ],
      ),
    );
  }
}

// ─── Indicador de pasos ─────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int paso;
  const _StepIndicator({required this.paso});

  @override
  Widget build(BuildContext context) {
    const labels = ['Centro', 'Datos', 'PIN', 'Cara', 'Confirmar'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Row(
        children: List.generate(labels.length, (i) {
          final activo = i == paso;
          final completado = i < paso;
          return Expanded(
            child: Column(
              children: [
                Container(
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: completado || activo
                        ? AppTheme.primaryOrange
                        : Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: activo ? FontWeight.bold : FontWeight.normal,
                    color: activo ? AppTheme.primaryOrange : Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ─── Despachador de pasos ────────────────────────────────────────────────────

class _PasoActual extends StatelessWidget {
  final RegistroViewModel vm;
  const _PasoActual({required this.vm});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      child: switch (vm.paso) {
        0 => const _Paso0Centro(key: ValueKey(0)),
        1 => const _Paso1Datos(key: ValueKey(1)),
        2 => const _Paso2Pin(key: ValueKey(2)),
        3 => const _Paso3Cara(key: ValueKey(3)),
        4 => const _Paso4Confirmar(key: ValueKey(4)),
        _ => const SizedBox.shrink(),
      },
    );
  }
}

// ─── Paso 0: código del centro ───────────────────────────────────────────────

class _Paso0Centro extends StatefulWidget {
  const _Paso0Centro({super.key});

  @override
  State<_Paso0Centro> createState() => _Paso0CentroState();
}

class _Paso0CentroState extends State<_Paso0Centro> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RegistroViewModel>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('¿A qué instalación perteneces?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'Ingresa el código que te proporcionó la administración de tu instalación.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 32),

          TextField(
            controller: _ctrl,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: 'Código de la instalación',
              hintText: 'Ej: FEPRO-2026',
              prefixIcon: const Icon(Icons.apartment_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              errorText: vm.errCentro,
            ),
            onChanged: (v) => context.read<RegistroViewModel>().codigoCentro = v,
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: vm.buscandoCentro
                  ? null
                  : () => context.read<RegistroViewModel>().buscarCentro(),
              child: vm.buscandoCentro
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Text('Buscar'),
            ),
          ),

          if (vm.nombreCentro != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryOrange.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppTheme.primaryOrange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Centro encontrado',
                            style: TextStyle(color: AppTheme.primaryOrange, fontWeight: FontWeight.bold, fontSize: 12)),
                        Text(vm.nombreCentro!,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.read<RegistroViewModel>().avanzar(),
                child: const Text('Continuar'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Paso 1: datos personales ─────────────────────────────────────────────────

class _Paso1Datos extends StatefulWidget {
  const _Paso1Datos({super.key});

  @override
  State<_Paso1Datos> createState() => _Paso1DatosState();
}

class _Paso1DatosState extends State<_Paso1Datos> {
  final _formKey = GlobalKey<FormState>();
  late final _nombreCtrl = TextEditingController();
  late final _apPatCtrl = TextEditingController();
  late final _apMatCtrl = TextEditingController();
  late final _telCtrl = TextEditingController();
  late final _casaCtrl = TextEditingController();

  @override
  void dispose() {
    for (final c in [_nombreCtrl, _apPatCtrl, _apMatCtrl, _telCtrl, _casaCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _casaError;

  void _continuar() {
    final vm = context.read<RegistroViewModel>();
    final usaSelector = vm.destinos.isNotEmpty;
    if (usaSelector && !vm.destinos.contains(_casaCtrl.text.trim())) {
      setState(() => _casaError = 'Selecciona tu casa de la lista');
      return;
    }
    setState(() => _casaError = null);
    if (!_formKey.currentState!.validate()) return;
    vm
      ..nombre = _nombreCtrl.text
      ..apellidoPaterno = _apPatCtrl.text
      ..apellidoMaterno = _apMatCtrl.text
      ..telefono = _telCtrl.text
      ..casaDestino = _casaCtrl.text
      ..avanzar();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RegistroViewModel>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tus datos personales',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),

            _Campo(ctrl: _nombreCtrl, label: 'Nombre(s)', icon: Icons.person_outline),
            const SizedBox(height: 14),
            _Campo(ctrl: _apPatCtrl, label: 'Apellido paterno', icon: Icons.person_outline),
            const SizedBox(height: 14),
            _Campo(ctrl: _apMatCtrl, label: 'Apellido materno', icon: Icons.person_outline),
            const SizedBox(height: 14),
            _Campo(
              ctrl: _telCtrl,
              label: 'Teléfono',
              icon: Icons.phone_outlined,
              required: false,
              tipo: TextInputType.phone,
            ),
            const SizedBox(height: 14),
            if (vm.destinos.isNotEmpty)
              Autocomplete<String>(
                optionsBuilder: (value) {
                  if (value.text.isEmpty) return vm.destinos;
                  final q = value.text.toLowerCase();
                  return vm.destinos.where((d) => d.toLowerCase().contains(q));
                },
                initialValue: TextEditingValue(text: _casaCtrl.text),
                onSelected: (v) => _casaCtrl.text = v,
                fieldViewBuilder: (context, ctrl, focusNode, onSubmit) {
                  return TextFormField(
                    controller: ctrl,
                    focusNode: focusNode,
                    onChanged: (v) => _casaCtrl.text = v,
                    decoration: InputDecoration(
                      labelText: 'Casa / Departamento',
                      hintText: 'Busca tu casa…',
                      prefixIcon: const Icon(Icons.home_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      errorText: _casaError,
                    ),
                  );
                },
              )
            else
              _Campo(
                ctrl: _casaCtrl,
                label: 'Casa / Departamento',
                hint: 'Ej: Torre B, Depto 102',
                icon: Icons.home_outlined,
              ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _continuar,
                child: const Text('Continuar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Campo extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String? hint;
  final IconData icon;
  final bool required;
  final TextInputType tipo;

  const _Campo({
    required this.ctrl,
    required this.label,
    this.hint,
    required this.icon,
    this.required = true,
    this.tipo = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      keyboardType: tipo,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null
          : null,
    );
  }
}

// ─── Paso 2: PIN ──────────────────────────────────────────────────────────────

class _Paso2Pin extends StatefulWidget {
  const _Paso2Pin({super.key});

  @override
  State<_Paso2Pin> createState() => _Paso2PinState();
}

class _Paso2PinState extends State<_Paso2Pin> {
  final _pinCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pinCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _continuar() {
    final p = _pinCtrl.text;
    final c = _confirmCtrl.text;
    if (p.length < 4 || p.length > 6) {
      setState(() => _error = 'El PIN debe tener entre 4 y 6 dígitos');
      return;
    }
    if (p != c) {
      setState(() => _error = 'Los PINs no coinciden');
      return;
    }
    final vm = context.read<RegistroViewModel>();
    vm
      ..pin = p
      ..pinConfirm = c
      ..avanzar();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Elige tu PIN de acceso',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Usarás este número para entrar a la instalación en el kiosko.',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 32),

          TextFormField(
            controller: _pinCtrl,
            obscureText: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
            decoration: InputDecoration(
              labelText: 'PIN (4–6 dígitos)',
              prefixIcon: const Icon(Icons.lock_outline),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 14),

          TextFormField(
            controller: _confirmCtrl,
            obscureText: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
            decoration: InputDecoration(
              labelText: 'Confirmar PIN',
              prefixIcon: const Icon(Icons.lock_outline),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
          ],

          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _continuar,
              child: const Text('Continuar'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Paso 3: captura de cara ─────────────────────────────────────────────────

class _Paso3Cara extends StatefulWidget {
  const _Paso3Cara({super.key});

  @override
  State<_Paso3Cara> createState() => _Paso3CaraState();
}

class _Paso3CaraState extends State<_Paso3Cara> {
  CameraController? _camCtrl;
  bool _iniciando = true;
  bool _capturando = false;
  bool _consentDado = false;
  String? _error;
  String? _fotoPath;

  @override
  void initState() {
    super.initState();
    _verificarConsentYIniciar();
  }

  @override
  void dispose() {
    _camCtrl?.dispose();
    super.dispose();
  }

  Future<void> _verificarConsentYIniciar() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getString(AppConstants.prefsRegistroConsentTs);
    if (ts != null) {
      setState(() => _consentDado = true);
      await _iniciarCamara();
    } else {
      setState(() => _iniciando = false);
    }
  }

  Future<void> _pedirConsent() async {
    final aceptado = await _mostrarConsentimiento(context);
    if (!mounted) return;
    if (aceptado) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.prefsRegistroConsentTs, DateTime.now().toIso8601String());
      setState(() => _consentDado = true);
      await _iniciarCamara();
    }
  }

  Future<void> _iniciarCamara() async {
    setState(() => _iniciando = true);
    try {
      final cameras = await availableCameras();
      final frontal = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      _camCtrl = CameraController(frontal, ResolutionPreset.medium, enableAudio: false);
      await _camCtrl!.initialize();
      if (mounted) setState(() => _iniciando = false);
    } catch (e) {
      if (mounted) setState(() { _error = 'Error al iniciar la cámara'; _iniciando = false; });
    }
  }

  Future<void> _capturar() async {
    if (_camCtrl == null || !_camCtrl!.value.isInitialized || _capturando) return;
    setState(() { _capturando = true; _error = null; });

    try {
      final foto = await _camCtrl!.takePicture();
      final inputImage = InputImage.fromFilePath(foto.path);
      final detector = FaceDetector(options: FaceDetectorOptions(minFaceSize: 0.3));
      final faces = await detector.processImage(inputImage);
      await detector.close();

      if (faces.isEmpty) {
        setState(() { _error = 'No se detectó un rostro. Asegúrate de estar frente a la cámara.'; _capturando = false; });
        return;
      }

      if (!mounted) return;
      setState(() { _fotoPath = foto.path; _capturando = false; });
      final vm = context.read<RegistroViewModel>();
      vm
        ..fotoCaraPath = foto.path
        ..avanzar();
    } catch (e) {
      setState(() { _error = 'Error al capturar la foto'; _capturando = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_iniciando) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryOrange));
    }

    if (!_consentDado) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.face_outlined, size: 72, color: AppTheme.primaryOrange),
            const SizedBox(height: 24),
            const Text('Captura de rostro',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            const Text(
              'Necesitamos una foto de tu rostro para que puedas acceder a la instalación mediante reconocimiento facial.',
              textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.privacy_tip_outlined),
                label: const Text('Ver aviso y continuar'),
                onPressed: _pedirConsent,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.read<RegistroViewModel>().avanzar(),
              child: const Text('Omitir (continuar sin foto)'),
            ),
          ],
        ),
      );
    }

    if (_fotoPath != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipOval(child: Image.file(File(_fotoPath!), width: 200, height: 200, fit: BoxFit.cover)),
            const SizedBox(height: 20),
            const Text('Rostro capturado', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            child: _camCtrl != null && _camCtrl!.value.isInitialized
                ? CameraPreview(_camCtrl!)
                : const Center(child: Text('Cámara no disponible')),
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13), textAlign: TextAlign.center),
          ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: _capturando
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.camera_alt_outlined),
                  label: const Text('Capturar'),
                  onPressed: _capturando ? null : _capturar,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.read<RegistroViewModel>().avanzar(),
                child: const Text('Omitir (continuar sin foto)'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Paso 4: confirmar y enviar ───────────────────────────────────────────────

class _Paso4Confirmar extends StatelessWidget {
  const _Paso4Confirmar({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RegistroViewModel>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Confirma tu solicitud',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),

          _Fila('Edificio', vm.nombreCentro ?? vm.codigoCentro),
          _Fila('Nombre', '${vm.nombre} ${vm.apellidoPaterno} ${vm.apellidoMaterno}'),
          _Fila('Casa / Depto', vm.casaDestino),
          if (vm.telefono.isNotEmpty) _Fila('Teléfono', vm.telefono),
          const _Fila('PIN', '••••'),
          _Fila('Foto de cara', vm.fotoCaraPath != null ? 'Capturada ✓' : 'Sin foto'),

          const SizedBox(height: 32),

          if (vm.errEnvio != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(vm.errEnvio!, style: const TextStyle(color: Colors.red)),
            ),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: vm.estado == RegistroEstado.cargando
                  ? null
                  : () async {
                      final ok = await vm.enviar();
                      if (ok && context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RegistroEstadoView(
                              codigoCentro: vm.codigoCentro.trim().toUpperCase(),
                              casaDestino: vm.casaDestino.trim(),
                              pin: vm.pin,
                            ),
                          ),
                        );
                      }
                    },
              child: vm.estado == RegistroEstado.cargando
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Text('Solicitar acceso'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  final String etiqueta;
  final String valor;
  const _Fila(this.etiqueta, this.valor);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(etiqueta, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          Expanded(
            child: Text(valor, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ─── Diálogo de privacidad biométrica ────────────────────────────────────────

Future<bool> _mostrarConsentimiento(BuildContext context) async {
  final bool? aceptado = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.privacy_tip_outlined, color: AppTheme.primaryOrange),
          SizedBox(width: 10),
          Text('Aviso de privacidad'),
        ],
      ),
      content: const Text(
        'Tu foto facial será almacenada por el administrador de la instalación para '
        'verificar tu identidad al ingresar. Puedes solicitar su eliminación '
        'contactando a la administración en cualquier momento. Tus datos '
        'no se comparten con terceros.',
        style: TextStyle(height: 1.6),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Aceptar'),
        ),
      ],
    ),
  );
  return aceptado ?? false;
}
