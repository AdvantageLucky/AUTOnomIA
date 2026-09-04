/// Una fila de GET /personas/me/identidades-mi-casa -- una identidad
/// (residente, invitado por QR, o visitante con INE) que ha visitado la
/// casa del residente autenticado, con la que puede "olvidar" el historial
/// acumulado. No incluye visitantes identificados solo por rostro (sin INE,
/// sin cuenta): esa identidad no tiene hoy un identificador estable contra
/// el que anclar un reset.
class IdentidadResumenModel {
  final int? personaId;
  final String? curp;
  final String nombre;
  final String tipoVisitante;
  final String tipoDocumento;
  final int totalVisitas;
  final DateTime ultimaVisita;

  IdentidadResumenModel({
    this.personaId,
    this.curp,
    required this.nombre,
    required this.tipoVisitante,
    required this.tipoDocumento,
    required this.totalVisitas,
    required this.ultimaVisita,
  });

  /// Clave estable para deduplicar/identificar en listas -- una identidad
  /// tiene personaId o curp, nunca ambos ni ninguno (lo garantiza el backend).
  String get key => personaId != null ? 'p$personaId' : 'c${curp ?? ''}';

  factory IdentidadResumenModel.fromJson(Map<String, dynamic> json) {
    return IdentidadResumenModel(
      personaId: json['persona_id'] as int?,
      curp: json['curp'] as String?,
      nombre: json['nombre'] as String? ?? '',
      tipoVisitante: json['tipo_visitante'] as String? ?? '',
      tipoDocumento: json['tipo_documento'] as String? ?? '',
      totalVisitas: json['total_visitas'] as int? ?? 0,
      ultimaVisita: DateTime.parse(json['ultima_visita'] as String),
    );
  }
}
