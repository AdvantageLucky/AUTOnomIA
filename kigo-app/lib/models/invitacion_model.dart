/// Una fila de GET/POST /personas/me/invitaciones.
class InvitacionModel {
  final int id;
  final String tipo;
  final String titular;
  final int destinoId;
  final int conteoUsos;
  final int? maxUsos;
  final DateTime? expiresAt;
  final DateTime? revokedAt;
  final DateTime createdAt;

  /// Solo viaja en la creación y en el listado propio del creador — nunca
  /// en lo que ve el kiosko ni ningún tercero.
  final String? token;

  InvitacionModel({
    required this.id,
    required this.tipo,
    required this.titular,
    required this.destinoId,
    required this.conteoUsos,
    this.maxUsos,
    this.expiresAt,
    this.revokedAt,
    required this.createdAt,
    this.token,
  });

  bool get vigente =>
      revokedAt == null &&
      (expiresAt == null || expiresAt!.isAfter(DateTime.now())) &&
      (maxUsos == null || conteoUsos < maxUsos!);

  factory InvitacionModel.fromJson(Map<String, dynamic> json) {
    return InvitacionModel(
      id: json['id'] as int,
      tipo: json['tipo'] as String,
      titular: json['titular'] as String,
      destinoId: json['destino_id'] as int,
      conteoUsos: json['conteo_usos'] as int,
      maxUsos: json['max_usos'] as int?,
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at'] as String) : null,
      revokedAt: json['revoked_at'] != null ? DateTime.parse(json['revoked_at'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      token: json['token'] as String?,
    );
  }
}

/// Una fila de GET /personas/me/invitaciones/recibidas — invitaciones que
/// otra Persona te hizo a ti, ya adjuntas por teléfono desde su creación.
class InvitacionRecibidaModel {
  final int id;
  final String tipo;
  final String titular;
  final String casaDestino;
  final String nombreInvita;
  final DateTime? expiresAt;
  final DateTime createdAt;

  InvitacionRecibidaModel({
    required this.id,
    required this.tipo,
    required this.titular,
    required this.casaDestino,
    required this.nombreInvita,
    this.expiresAt,
    required this.createdAt,
  });

  factory InvitacionRecibidaModel.fromJson(Map<String, dynamic> json) {
    return InvitacionRecibidaModel(
      id: json['id'] as int,
      tipo: json['tipo'] as String,
      titular: json['titular'] as String,
      casaDestino: json['casa_destino'] as String? ?? '',
      nombreInvita: json['nombre_invita'] as String? ?? '',
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
