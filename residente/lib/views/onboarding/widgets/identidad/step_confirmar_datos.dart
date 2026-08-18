import 'package:flutter/material.dart';
import '../../../../models/ine_ocr_model.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/kigo_primary_button.dart';
import '../../../../widgets/kigo_text_field.dart';

/// Segundo paso del wizard de identidad: confirma/corrige nombre, apellidos
/// y CURP. El nombre completo NO se separa automáticamente en nombre/
/// apellidos (el orden en que aparecen en una INE no es confiable) —
/// se muestra como referencia y la persona llena los 3 campos a mano.
class StepConfirmarDatos extends StatefulWidget {
  final IneOcrResult resultadoOcr;
  final void Function(String nombre, String apellidoPaterno, String apellidoMaterno, String curp)
      onConfirmado;

  const StepConfirmarDatos({super.key, required this.resultadoOcr, required this.onConfirmado});

  @override
  State<StepConfirmarDatos> createState() => _StepConfirmarDatosState();
}

class _StepConfirmarDatosState extends State<StepConfirmarDatos> {
  final _nombreCtrl = TextEditingController();
  final _apellidoPaternoCtrl = TextEditingController();
  final _apellidoMaternoCtrl = TextEditingController();
  late final TextEditingController _curpCtrl;
  String? _errorLocal;

  @override
  void initState() {
    super.initState();
    _curpCtrl = TextEditingController(text: widget.resultadoOcr.curp ?? '');
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoPaternoCtrl.dispose();
    _apellidoMaternoCtrl.dispose();
    _curpCtrl.dispose();
    super.dispose();
  }

  void _continuar() {
    final nombre = _nombreCtrl.text.trim();
    final apellidoPaterno = _apellidoPaternoCtrl.text.trim();
    if (nombre.isEmpty || apellidoPaterno.isEmpty) {
      setState(() => _errorLocal = 'Nombre y apellido paterno son requeridos');
      return;
    }
    setState(() => _errorLocal = null);
    widget.onConfirmado(
      nombre,
      apellidoPaterno,
      _apellidoMaternoCtrl.text.trim(),
      _curpCtrl.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nombreDetectado = widget.resultadoOcr.nombreCompleto;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Confirma tus datos', style: Theme.of(context).textTheme.headlineSmall),
          if (nombreDetectado != null) ...[
            const SizedBox(height: 6),
            Text(
              'Detectamos: $nombreDetectado',
              style: const TextStyle(color: AppTheme.textDimmed, fontSize: 13),
            ),
          ],
          const SizedBox(height: 20),
          KigoTextField(controller: _nombreCtrl, label: 'Nombre'),
          const SizedBox(height: 12),
          KigoTextField(controller: _apellidoPaternoCtrl, label: 'Apellido paterno'),
          const SizedBox(height: 12),
          KigoTextField(controller: _apellidoMaternoCtrl, label: 'Apellido materno (opcional)'),
          const SizedBox(height: 12),
          KigoTextField(controller: _curpCtrl, label: 'CURP'),
          if (_errorLocal case final mensaje?) ...[
            const SizedBox(height: 8),
            Text(mensaje, style: const TextStyle(color: AppTheme.error, fontSize: 13)),
          ],
          const SizedBox(height: 20),
          KigoPrimaryButton(label: 'Continuar', onPressed: _continuar),
        ],
      ),
    );
  }
}
