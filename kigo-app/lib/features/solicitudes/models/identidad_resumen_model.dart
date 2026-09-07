/// Una fila de GET /personas/me/identidades-mi-casa -- una identidad
/// (residente, invitado por QR, visitante con INE, o visitante sin ningún
/// dato salvo su cara) que ha visitado la casa del residente autenticado,
/// con la que puede "olvidar" el historial acumulado.
class IdentidadResumenModel {
  final int? personaId;
  final String? curp;
  /// Presente cuando la identidad es un cluster de solo-rostro (sin
  /// personaId ni curp) -- "el sistema no lo conoce". El reset para este
  /// caso se pide contra esta visita puntual (ver
  /// IdentidadesConfianzaViewModel.resetear).
  final int? visitaRepresentativaId;
  final String nombre;
  final String tipoVisitante;
  final String tipoDocumento;
  final int totalVisitas;
  final DateTime ultimaVisita;
  final String? fotoUrl;
  final int? scorePct;

  IdentidadResumenModel({
    this.personaId,
    this.curp,
    this.visitaRepresentativaId,
    required this.nombre,
    required this.tipoVisitante,
    required this.tipoDocumento,
    required this.totalVisitas,
    required this.ultimaVisita,
    this.fotoUrl,
    this.scorePct,
  });

  /// true cuando no hay ni cuenta ni INE de por medio -- solo se identificó
  /// por su cara. El nombre siempre viene vacío en este caso.
  bool get sinIdentificar => personaId == null && (curp == null || curp!.isEmpty);

  /// Clave estable para deduplicar/identificar en listas.
  String get key {
    if (personaId != null) return 'p$personaId';
    if (curp != null && curp!.isNotEmpty) return 'c$curp';
    return 'r${visitaRepresentativaId ?? 0}';
  }

  factory IdentidadResumenModel.fromJson(Map<String, dynamic> json) {
    return IdentidadResumenModel(
      personaId: json['persona_id'] as int?,
      curp: json['curp'] as String?,
      visitaRepresentativaId: json['visita_representativa_id'] as int?,
      nombre: json['nombre'] as String? ?? '',
      tipoVisitante: json['tipo_visitante'] as String? ?? '',
      tipoDocumento: json['tipo_documento'] as String? ?? '',
      totalVisitas: json['total_visitas'] as int? ?? 0,
      ultimaVisita: DateTime.parse(json['ultima_visita'] as String),
      fotoUrl: json['foto_url'] as String?,
      scorePct: json['score_pct'] as int?,
    );
  }
}
