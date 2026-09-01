import 'package:flutter/material.dart';
import '../../../../models/ine_ocr_model.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/kigo_primary_button.dart';
import '../../../../widgets/kigo_text_field.dart';

/// Segundo paso del wizard de identidad: confirma/corrige nombre, apellidos
/// y CURP. Los 3 campos se precargan cuando el OCR reconoció el bloque
/// estándar de INE (apellido paterno/materno/nombre en 3 líneas fijas bajo
/// "NOMBRE" -- ver DetectorIneServicio); si el OCR solo encontró el nombre
/// en un formato menos estándar, quedan vacíos con el texto detectado como
/// referencia y la persona los llena a mano, como antes.
class StepConfirmarDatos extends StatefulWidget {
  final IneOcrResult resultadoOcr;
  final void Function(String nombre, String apellidoPaterno, String apellidoMaterno, String curp)
      onConfirmado;

  const StepConfirmarDatos({super.key, required this.resultadoOcr, required this.onConfirmado});

  @override
  State<StepConfirmarDatos> createState() => _StepConfirmarDatosState();
}

class _StepConfirmarDatosState extends State<StepConfirmarDatos> {
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _apellidoPaternoCtrl;
  late final TextEditingController _apellidoMaternoCtrl;
  late final TextEditingController _curpCtrl;
  String? _errorLocal;

  @override
  void initState() {
    super.initState();
    final ocr = widget.resultadoOcr;
    // Solo se precargan cuando el OCR separó las 3 líneas del bloque
    // estándar de INE (ver DetectorIneServicio) -- si solo hay
    // nombreCompleto sin separar, esos campos quedan vacíos y el texto de
    // referencia abajo del título es la única ayuda, como antes.
    _apellidoPaternoCtrl = TextEditingController(text: ocr.apellidoPaterno ?? '');
    _apellidoMaternoCtrl = TextEditingController(text: ocr.apellidoMaterno ?? '');
    _nombreCtrl = TextEditingController(text: ocr.nombre ?? '');
    _curpCtrl = TextEditingController(text: ocr.curp ?? '');
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
    // Si ya se precargaron los 3 campos, el texto de referencia sería
    // redundante -- solo se muestra cuando el OCR no pudo separarlos.
    final nombreDetectado =
        widget.resultadoOcr.apellidoPaterno == null ? widget.resultadoOcr.nombreCompleto : null;
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
