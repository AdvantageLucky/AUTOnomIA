import '../utils/constants.dart';

/// Una fila de GET /personas/me/visitas/pendientes.
class VisitaPendienteModel {
  final int id;
  final String titular;
  final String casaDestino;

  /// Foto de rostro que capturó el kiosko, ya reanclada al origen de esta app
  /// (ver [AppConstants.mediaUrl]). Vacía cuando el flujo del kiosko no pide
  /// rostro o la captura falló.
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
      fotoRostroUrl: AppConstants.mediaUrl(json['foto_rostro_url'] as String? ?? ''),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
