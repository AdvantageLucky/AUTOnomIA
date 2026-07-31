import 'package:flutter/foundation.dart';
import 'package:kigo_kiosco/features/registro/services/kiosko_servicio.dart';

enum PinEstado { ingresando, cargando, error }

class ResidentPinViewModel extends ChangeNotifier {
  String _pin = '';
  PinEstado _estado = PinEstado.ingresando;
  String? _errorMsg;
  String? _nombreResidente;
  String? _casaDestino;

  String get pin => _pin;
  PinEstado get estado => _estado;
  String? get errorMsg => _errorMsg;
  String? get nombreResidente => _nombreResidente;
  String? get casaDestino => _casaDestino;

  bool get isCargando => _estado == PinEstado.cargando;

  static const int minLength = 4;
  static const int maxLength = 6;

  bool get puedeConfirmar => _pin.length >= minLength && !isCargando;

  void addDigit(String digit) {
    if (_pin.length >= maxLength || isCargando) return;
    _pin += digit;
    _errorMsg = null;
    _estado = PinEstado.ingresando;
    notifyListeners();
  }

  void removeLastDigit() {
    if (_pin.isEmpty || isCargando) return;
    _pin = _pin.substring(0, _pin.length - 1);
    _errorMsg = null;
    _estado = PinEstado.ingresando;
    notifyListeners();
  }

  void clear() {
    _pin = '';
    _errorMsg = null;
    _estado = PinEstado.ingresando;
    notifyListeners();
  }

  Future<bool> confirmar() async {
    if (!puedeConfirmar) return false;

    _estado = PinEstado.cargando;
    _errorMsg = null;
    notifyListeners();

    try {
      final data = await KioskoServicio().validarPinResidente(_pin);
      _nombreResidente = data['nombre'] as String?;
      _casaDestino = data['casa_destino'] as String?;
      _estado = PinEstado.ingresando;
      notifyListeners();
      return true;
    } catch (e) {
      _pin = '';
      _errorMsg = e.toString().replaceFirst('Exception: ', '');
      _estado = PinEstado.error;
      notifyListeners();
      return false;
    }
  }
}
