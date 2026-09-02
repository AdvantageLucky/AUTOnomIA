import 'package:flutter/foundation.dart';

class ResidentWelcomeViewModel extends ChangeNotifier {
  final String nombre;
  final String casaDestino;

  /// true si el reconocimiento (PIN o rostro) fue de un invitado frecuente
  /// (Membresia.Rol=invitado_frecuente en el backend) -- alguien con acceso
  /// recurrente prestado por un residente, no un residente real. Sin esto
  /// el kiosko saludaba a ambos exactamente igual.
  final bool esInvitadoFrecuente;

  ResidentWelcomeViewModel({
    required this.nombre,
    required this.casaDestino,
    this.esInvitadoFrecuente = false,
  });
}
