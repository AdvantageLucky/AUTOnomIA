import 'package:flutter/material.dart';
import '../services/registro_service.dart';
import '../theme/app_theme.dart';

class RegistroEstadoView extends StatefulWidget {
  final String codigoCentro;
  final String casaDestino;
  final String pin;

  const RegistroEstadoView({
    super.key,
    required this.codigoCentro,
    required this.casaDestino,
    required this.pin,
  });

  @override
  State<RegistroEstadoView> createState() => _RegistroEstadoViewState();
}

class _RegistroEstadoViewState extends State<RegistroEstadoView> {
  final _service = RegistroService();
  String _status = 'pendiente';
  bool _consultando = false;
  String? _error;

  Future<void> _verificar() async {
    setState(() { _consultando = true; _error = null; });
    try {
      final s = await _service.consultarEstado(
        codigoCentro: widget.codigoCentro,
        casaDestino: widget.casaDestino,
        pin: widget.pin,
      );
      setState(() { _status = s; _consultando = false; });
    } catch (e) {
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _consultando = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Estado de tu solicitud')),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIcono(),
            const SizedBox(height: 24),
            _buildMensaje(),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13), textAlign: TextAlign.center),
            ],
            const SizedBox(height: 32),
            if (_status == 'pendiente')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: _consultando
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.refresh_rounded),
                  label: const Text('Verificar estado'),
                  onPressed: _consultando ? null : _verificar,
                ),
              ),
            if (_status == 'activo') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                  child: const Text('Ir al inicio'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcono() {
    return switch (_status) {
      'activo' => const Icon(Icons.check_circle_rounded, size: 96, color: Colors.green),
      'rechazado' => const Icon(Icons.cancel_rounded, size: 96, color: Colors.red),
      _ => const Icon(Icons.hourglass_top_rounded, size: 96, color: AppTheme.primaryOrange),
    };
  }

  Widget _buildMensaje() {
    return switch (_status) {
      'activo' => const Column(children: [
          Text('¡Solicitud aprobada!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          SizedBox(height: 12),
          Text(
            'Ya puedes ingresar a la instalación en el kiosko usando tu PIN.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, height: 1.5),
          ),
        ]),
      'rechazado' => const Column(children: [
          Text('Solicitud rechazada',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          SizedBox(height: 12),
          Text(
            'Tu solicitud no fue aprobada. Contacta a la administración de la instalación para más información.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, height: 1.5),
          ),
        ]),
      _ => const Column(children: [
          Text('Solicitud en revisión',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          SizedBox(height: 12),
          Text(
            'Tu solicitud está siendo revisada por el administrador de la instalación. '
            'Toca "Verificar estado" para comprobar si ya fue aprobada.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, height: 1.5),
          ),
        ]),
    };
  }
}
