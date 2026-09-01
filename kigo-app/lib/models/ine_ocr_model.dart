/// Resultado del OCR de una INE — CURP y nombre.
///
/// El INE moderno imprime apellido paterno, apellido materno y nombre(s)
/// como 3 líneas consecutivas y en ese orden fijo bajo la etiqueta
/// "NOMBRE" -- cuando el detector reconoce ese bloque estándar, separarlas
/// es confiable y quedan en [apellidoPaterno]/[apellidoMaterno]/[nombre]
/// para precargar los 3 campos. Cuando el detector solo encuentra el
/// nombre en un formato menos estándar (todo en una línea, u otra
/// etiqueta), esos 3 campos quedan null y solo se llena [nombreCompleto]
/// como referencia -- ahí sí el orden no es confiable y la persona
/// completa a mano, como antes.
class IneOcrResult {
  final String pathFotoIne;
  final String? curp;
  final String? nombreCompleto;
  final String? apellidoPaterno;
  final String? apellidoMaterno;
  final String? nombre;

  IneOcrResult({
    required this.pathFotoIne,
    this.curp,
    this.nombreCompleto,
    this.apellidoPaterno,
    this.apellidoMaterno,
    this.nombre,
  });
}
