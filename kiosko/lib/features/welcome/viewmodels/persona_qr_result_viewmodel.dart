import 'package:flutter/foundation.dart';
import 'package:kigo_kiosco/features/registro/services/kiosko_servicio.dart';

enum PersonaQrResultEstado { cargando, miembro, invitado, desconocido, error }

/// Resultado de escanear el QR personal de la app Kigo (persona_id:firma) —
/// distinto del QR de invitación por token que ya manejaba QrResultViewModel.
class PersonaQrResultViewModel extends ChangeNotifier {
  final String qrValue;

  PersonaQrResultEstado _estado = PersonaQrResultEstado.cargando;
  String? _nombre;
  String? _casaDestino;
  String? _errorMsg;

  PersonaQrResultEstado get estado => _estado;
  String? get nombre => _nombre;
  String? get casaDestino => _casaDestino;
  String? get errorMsg => _errorMsg;

  PersonaQrResultViewModel({required this.qrValue}) {
    _procesar();
  }

  Future<void> _procesar() async {
    try {
      final partes = qrValue.split(':');
      if (partes.length < 2) {
        throw Exception('Código QR con formato inválido');
      }
      final personaId = int.parse(partes.first);
      final firma = partes.sublist(1).join(':');

      final resultado = await KioskoServicio().verificarQrPersona(personaId, firma);
      _nombre = resultado['nombre'] as String?;
      _casaDestino = resultado['casa_destino'] as String?;

      final estadoStr = (resultado['estado'] as String? ?? '').toLowerCase();
      final tipoStr = (resultado['tipo'] as String? ?? '').toLowerCase();

      if (estadoStr == 'miembro' || tipoStr == 'residente') {
        _estado = PersonaQrResultEstado.miembro;
      } else if (estadoStr == 'invitado') {
        _estado = PersonaQrResultEstado.invitado;
      } else {
        _estado = PersonaQrResultEstado.desconocido;
      }
    } catch (e) {
      _errorMsg = e.toString().replaceFirst('Exception: ', '');
      _estado = PersonaQrResultEstado.error;
    }
    notifyListeners();
  }
}
