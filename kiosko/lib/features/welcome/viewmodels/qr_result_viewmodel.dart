import 'package:flutter/foundation.dart';
import 'package:kigo_kiosco/features/registro/services/kiosko_servicio.dart';

enum QrResultEstado { cargando, exitoso, error }

class QrResultViewModel extends ChangeNotifier {
  final String token;

  QrResultEstado _estado = QrResultEstado.cargando;
  String? _titular;
  String? _casaDestino;
  String? _errorMsg;

  QrResultEstado get estado => _estado;
  String? get titular => _titular;
  String? get casaDestino => _casaDestino;
  String? get errorMsg => _errorMsg;

  QrResultViewModel({required this.token}) {
    _procesar();
  }

  Future<void> _procesar() async {
    try {
      final resultado = await KioskoServicio().usarInvitacion(token);
      _titular = resultado['titular'] as String?;
      _casaDestino = resultado['casa_destino'] as String?;
      _estado = QrResultEstado.exitoso;
    } catch (e) {
      _errorMsg = e.toString().replaceFirst('Exception: ', '');
      _estado = QrResultEstado.error;
    }
    notifyListeners();
  }
}
