import '../utils/constants.dart';
import 'score_ia_model.dart';

/// Una fila de GET /personas/me/visitas/pendientes.
class VisitaPendienteModel {
  final int id;
  final String titular;
  final String casaDestino;

  /// Foto de rostro que capturó el kiosko, ya reanclada al origen de esta
  /// app (ver [AppConstants.mediaUrl]). Vacía cuando el flujo del kiosko no
  /// pide rostro o la captura falló.
  final String fotoRostroUrl;

  /// Fotos de identificación y placa -- mismo reanclaje. Vacías si el flujo
  /// de este kiosko no las pide (ver KioskoConfig.pasosSinInvitacion).
  final String fotoDocumentoUrl;
  final String fotoPlacaUrl;
  final String placa;
  final String tipoVisitante; // 'VISITANTE' | 'INVITADO' | 'RESIDENTE'

  /// Análisis de confianza, ya recortado por el backend a lo que es seguro
  /// mostrarle a un residente (ver ScoreIaModel). Null si no se calculó.
  final ScoreIaModel? scoreIa;

  final DateTime createdAt;

  VisitaPendienteModel({
    required this.id,
    required this.titular,
    required this.casaDestino,
    required this.fotoRostroUrl,
    this.fotoDocumentoUrl = '',
    this.fotoPlacaUrl = '',
    this.placa = '',
    this.tipoVisitante = '',
    this.scoreIa,
    required this.createdAt,
  });

  factory VisitaPendienteModel.fromJson(Map<String, dynamic> json) {
    return VisitaPendienteModel(
      id: json['id'] as int,
      titular: json['titular'] as String,
      casaDestino: json['casa_destino'] as String,
      fotoRostroUrl: AppConstants.mediaUrl(json['foto_rostro_url'] as String? ?? ''),
      fotoDocumentoUrl: AppConstants.mediaUrl(json['foto_documento_url'] as String? ?? ''),
      fotoPlacaUrl: AppConstants.mediaUrl(json['foto_placa_url'] as String? ?? ''),
      placa: json['placa'] as String? ?? '',
      tipoVisitante: json['tipo_visitante'] as String? ?? '',
      scoreIa: json['score_ia'] != null
          ? ScoreIaModel.fromJson(json['score_ia'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
