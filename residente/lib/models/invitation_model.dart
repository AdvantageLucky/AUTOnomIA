class InvitationModel {
  final int id;
  final String? token; // solo disponible en la respuesta de creación o cache local
  final String tipo; // PERSONAL | GRUPAL
  final String titular;
  final int destinoId;
  final int conteoUsos;
  final int? maxUsos;
  final DateTime? expiresAt;
  final DateTime? revokedAt;
  final DateTime createdAt;

  const InvitationModel({
    required this.id,
    this.token,
    required this.tipo,
    required this.titular,
    required this.destinoId,
    required this.conteoUsos,
    this.maxUsos,
    this.expiresAt,
    this.revokedAt,
    required this.createdAt,
  });

  bool get isRevoked => revokedAt != null;

  factory InvitationModel.fromJson(Map<String, dynamic> json) {
    return InvitationModel(
      id: json['id'] as int,
      token: json['token'] as String?,
      tipo: json['tipo'] as String,
      titular: json['titular'] as String,
      destinoId: json['destino_id'] as int,
      conteoUsos: json['conteo_usos'] as int,
      maxUsos: json['max_usos'] as int?,
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
      revokedAt: json['revoked_at'] != null ? DateTime.parse(json['revoked_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  InvitationModel copyWith({String? token}) {
    return InvitationModel(
      id: id,
      token: token ?? this.token,
      tipo: tipo,
      titular: titular,
      destinoId: destinoId,
      conteoUsos: conteoUsos,
      maxUsos: maxUsos,
      expiresAt: expiresAt,
      revokedAt: revokedAt,
      createdAt: createdAt,
    );
  }
}
