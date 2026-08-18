/// Resultado del OCR de una INE — solo lo que la app necesita: CURP y
/// nombre completo (crudo, sin separar en nombre/apellidos — eso lo hace
/// la persona a mano en la pantalla de confirmación, porque el orden en
/// que aparecen nombre/apellidos en una INE no es lo bastante confiable
/// para adivinarlo).
class IneOcrResult {
  final String pathFotoIne;
  final String? curp;
  final String? nombreCompleto;

  IneOcrResult({required this.pathFotoIne, this.curp, this.nombreCompleto});
}
