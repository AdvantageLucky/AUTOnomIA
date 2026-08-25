import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/ine_ocr_model.dart';
import '../../../theme/app_theme.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import 'identidad/step_confirmar_datos.dart';
import 'identidad/step_escanear_ine.dart';
import 'identidad/step_escanear_rostro.dart';

enum _SubPaso { ine, confirmar, rostro }

/// Wizard de identidad (INE + confirmar + rostro) — reemplaza el viejo paso
/// de solo texto "Perfil". Coordina sus 3 sub-pasos y, al final, junta todo
/// en un solo POST /personas/me/identidad. Ver spec
/// 2026-08-17-kigo-app-rediseno-design.md §10.
class StepIdentidad extends StatefulWidget {
  final VoidCallback onCompletado;
  const StepIdentidad({super.key, required this.onCompletado});

  @override
  State<StepIdentidad> createState() => _StepIdentidadState();
}

class _StepIdentidadState extends State<StepIdentidad> {
  _SubPaso _subPaso = _SubPaso.ine;
  IneOcrResult? _resultadoOcr;
  String? _nombre, _apellidoPaterno, _apellidoMaterno, _curp;
  bool _enviando = false;
  String? _errorEnvio;

  void _onEscaneado(IneOcrResult resultado) {
    setState(() {
      _resultadoOcr = resultado;
      _subPaso = _SubPaso.confirmar;
    });
  }

  void _onConfirmado(String nombre, String apellidoPaterno, String apellidoMaterno, String curp) {
    setState(() {
      _nombre = nombre;
      _apellidoPaterno = apellidoPaterno;
      _apellidoMaterno = apellidoMaterno;
      _curp = curp;
      _subPaso = _SubPaso.rostro;
    });
  }

  Future<void> _onRostroCapturado(String pathFoto, List<double> embedding) async {
    setState(() {
      _enviando = true;
      _errorEnvio = null;
    });
    final auth = context.read<AuthViewModel>();
    try {
      await auth.completarIdentidad(
        nombre: _nombre!,
        apellidoPaterno: _apellidoPaterno!,
        apellidoMaterno: _apellidoMaterno!,
        curp: _curp!,
        pathFotoIne: _resultadoOcr!.pathFotoIne,
        pathFotoRostro: pathFoto,
        embedding: embedding,
      );
      widget.onCompletado();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorEnvio = auth.error ?? 'No se pudo completar tu identidad';
        _subPaso = _SubPaso.confirmar;
      });
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_enviando) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        if (_errorEnvio != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _errorEnvio!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.error, fontSize: 13),
            ),
          ),
        Expanded(
          child: switch (_subPaso) {
            _SubPaso.ine => StepEscanearIne(onEscaneado: _onEscaneado),
            _SubPaso.confirmar =>
              StepConfirmarDatos(resultadoOcr: _resultadoOcr!, onConfirmado: _onConfirmado),
            _SubPaso.rostro => StepEscanearRostro(onCapturado: _onRostroCapturado),
          },
        ),
      ],
    );
  }
}
