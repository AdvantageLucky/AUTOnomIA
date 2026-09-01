import '../utils/constants.dart';
import 'score_ia_model.dart';

/// Una fila de GET /personas/me/visitas/historial.
///
/// Es la misma visita que en pendientes, pero aquí ya está resuelta: por eso
/// trae [estado] y no acciones.
class VisitaHistorialModel {
  final int id;
  final String titular;
  final String casaDestino;
  final String fotoRostroUrl;
  final String fotoDocumentoUrl;
  final String fotoPlacaUrl;
  final String placa;
  final String tipoVisitante;
  final ScoreIaModel? scoreIa;

  /// PENDIENTE · APROBADO · RECHAZADO · REVISION, tal cual lo guarda el backend.
  final String estado;

  final DateTime createdAt;

  /// Quién resolvió: "Aprobada por Ana" en la app. Vacío mientras sigue
  /// pendiente.
  final String autorizadoPorNombre;

  VisitaHistorialModel({
    required this.id,
    required this.titular,
    required this.casaDestino,
    required this.fotoRostroUrl,
    this.fotoDocumentoUrl = '',
    this.fotoPlacaUrl = '',
    this.placa = '',
    this.tipoVisitante = '',
    this.scoreIa,
    required this.estado,
    required this.createdAt,
    required this.autorizadoPorNombre,
  });

  factory VisitaHistorialModel.fromJson(Map<String, dynamic> json) {
    return VisitaHistorialModel(
      id: json['id'] as int,
      titular: json['titular'] as String? ?? '',
      casaDestino: json['casa_destino'] as String? ?? '',
      fotoRostroUrl: AppConstants.mediaUrl(json['foto_rostro_url'] as String? ?? ''),
      fotoDocumentoUrl: AppConstants.mediaUrl(json['foto_documento_url'] as String? ?? ''),
      fotoPlacaUrl: AppConstants.mediaUrl(json['foto_placa_url'] as String? ?? ''),
      placa: json['placa'] as String? ?? '',
      tipoVisitante: json['tipo_visitante'] as String? ?? '',
      scoreIa: json['score_ia'] != null
          ? ScoreIaModel.fromJson(json['score_ia'] as Map<String, dynamic>)
          : null,
      estado: json['estado'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      autorizadoPorNombre: json['autorizado_por_nombre'] as String? ?? '',
    );
  }
}
