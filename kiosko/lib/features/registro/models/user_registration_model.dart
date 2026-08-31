/* MODELO DE DATOS PARA EL REGISTRO DEL USUARIO */

class UserRegistrationModel {
  // Datos extraídos del INE mediante el OCR local
  String? nombreCompleto;
  String? curp;

  // Rutas de los archivos temporales de las fotos guardadas en el teléfono
  String? pathFotoIne;
  String? pathFotoRostro;
  String? pathFotoPlaca;

  // Nitidez de pathFotoIne (EvidenciaCalidadServicio): el número crudo de
  // la varianza del Laplaciano y la etiqueta derivada de él, para el
  // dataset calificable de calidad de captura.
  double? nitidezIneScore;
  String? calidadIne;

  // Datos de la visita capturados en la pantalla de confirmación
  String? casaDestino;
  String? placa;

  // Token de la invitación escaneada. Null en el flujo sin invitación.
  String? tokenInvitacion;

  // Constructor de la clase
  // NOTA: todos los campos son opcionales al inicio porque el usuario los va llenando paso a paso
  UserRegistrationModel({
    this.nombreCompleto,
    this.curp,
    this.pathFotoIne,
    this.pathFotoRostro,
    this.pathFotoPlaca,
    this.casaDestino,
    this.placa,
    this.tokenInvitacion,
  });

  // Método por si en el futuro se necesita limpiar los datos y reiniciar el registro
  void clear() {
    nombreCompleto = null;
    curp = null;
    pathFotoIne = null;
    pathFotoRostro = null;
    pathFotoPlaca = null;
    nitidezIneScore = null;
    calidadIne = null;
    casaDestino = null;
    placa = null;
    tokenInvitacion = null;
  }

  // true cuando el registro viene de una invitación con QR ya validada
  bool get esInvitado => tokenInvitacion != null;

  // Método para verificar si el paso del INE ya tiene los datos mínimos
  bool get tieneDatosIne => curp != null && curp!.length == 18 && pathFotoIne != null;

  /// true si la visita se puede identificar después en la bitácora.
  ///
  /// En el flujo peatonal puede ser INE o foto de rostro; en el vehicular,
  /// la placa o foto de rostro es el identificador (ADR-0024).
  bool get tieneIdentificador =>
      tieneDatosIne ||
      (placa != null && placa!.isNotEmpty) ||
      (pathFotoRostro != null && pathFotoRostro!.isNotEmpty);
}