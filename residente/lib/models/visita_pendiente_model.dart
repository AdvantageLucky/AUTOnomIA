/// Una fila de GET /personas/me/visitas/pendientes.
class VisitaPendienteModel {
  final int id;
  final String titular;
  final String casaDestino;
  final String fotoRostroUrl;
  final DateTime createdAt;

  VisitaPendienteModel({
    required this.id,
    required this.titular,
    required this.casaDestino,
    required this.fotoRostroUrl,
    required this.createdAt,
  });

  factory VisitaPendienteModel.fromJson(Map<String, dynamic> json) {
    return VisitaPendienteModel(
      id: json['id'] as int,
      titular: json['titular'] as String,
      casaDestino: json['casa_destino'] as String,
      fotoRostroUrl: json['foto_rostro_url'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
