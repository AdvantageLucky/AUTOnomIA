/* MODELO DE DATOS PARA EL REGISTRO DEL USUARIO */

class UserRegistrationModel {
  // Datos extraídos del INE mediante el OCR local
  String? nombreCompleto;
  String? curp;
  String? claveElector;
  
  // Rutas de los archivos temporales de las fotos guardadas en el teléfono
  String? pathFotoIne;
  String? pathFotoRostro;

  // Constructor de la clase 
  // NOTA: todos los campos son opcionales al inicio porque el usuario los va llenando paso a paso
  UserRegistrationModel({
    this.nombreCompleto,
    this.curp,
    this.claveElector,
    this.pathFotoIne,
    this.pathFotoRostro,
  });

  // Método por si en el futuro se necesita limpiar los datos y reiniciar el registro
  void clear() {
    nombreCompleto = null;
    curp = null;
    claveElector = null;
    pathFotoIne = null;
    pathFotoRostro = null;
  }

  // Método para verificar si el paso del INE ya tiene los datos mínimos
  bool get tieneDatosIne => curp != null && claveElector != null;
}