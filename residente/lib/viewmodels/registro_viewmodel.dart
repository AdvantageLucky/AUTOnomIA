import 'package:flutter/foundation.dart';
import '../services/registro_service.dart';

enum RegistroEstado { inicial, cargando, exito, error }

class RegistroViewModel extends ChangeNotifier {
  final _service = RegistroService();

  int paso = 0;

  // Paso 0 — centro
  String codigoCentro = '';
  String? nombreCentro;
  String? errCentro;
  bool buscandoCentro = false;
  List<String> destinos = [];

  // Paso 1 — datos personales
  String nombre = '';
  String apellidoPaterno = '';
  String apellidoMaterno = '';
  String telefono = '';
  String casaDestino = '';

  // Paso 2 — PIN
  String pin = '';
  String pinConfirm = '';

  // Paso 3 — cara
  String? fotoCaraPath;
  bool consentDado = false;

  // Estado del envío
  RegistroEstado estado = RegistroEstado.inicial;
  String? errEnvio;

  Future<void> buscarCentro() async {
    errCentro = null;
    buscandoCentro = true;
    notifyListeners();

    try {
      final data = await _service.buscarCentro(codigoCentro.trim().toUpperCase());
      nombreCentro = data['nombre'] as String?;
      destinos = await _service.listarDestinos(codigoCentro.trim().toUpperCase());
      buscandoCentro = false;
      notifyListeners();
    } catch (e) {
      errCentro = e.toString().replaceFirst('Exception: ', '');
      nombreCentro = null;
      buscandoCentro = false;
      notifyListeners();
    }
  }

  bool get paso0Valido => nombreCentro != null;

  bool get paso1Valido =>
      nombre.trim().isNotEmpty &&
      apellidoPaterno.trim().isNotEmpty &&
      apellidoMaterno.trim().isNotEmpty &&
      casaDestino.trim().isNotEmpty;

  bool get paso2Valido =>
      pin.length >= 4 && pin.length <= 6 && pin == pinConfirm;

  bool get paso3Valido => fotoCaraPath != null;

  void avanzar() {
    if (paso < 4) {
      paso++;
      notifyListeners();
    }
  }

  void retroceder() {
    if (paso > 0) {
      paso--;
      notifyListeners();
    }
  }

  Future<bool> enviar() async {
    estado = RegistroEstado.cargando;
    errEnvio = null;
    notifyListeners();

    try {
      await _service.autoRegistrar(
        codigoCentro: codigoCentro.trim().toUpperCase(),
        nombre: nombre.trim(),
        apellidoPaterno: apellidoPaterno.trim(),
        apellidoMaterno: apellidoMaterno.trim(),
        telefono: telefono.trim(),
        casaDestino: casaDestino.trim(),
        pin: pin,
        fotoCaraPath: fotoCaraPath,
      );
      estado = RegistroEstado.exito;
      notifyListeners();
      return true;
    } catch (e) {
      errEnvio = e.toString().replaceFirst('Exception: ', '');
      estado = RegistroEstado.error;
      notifyListeners();
      return false;
    }
  }
}
