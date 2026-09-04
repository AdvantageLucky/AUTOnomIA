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
  final String motivo;

  /// Solo viaja en la creación y en el listado propio del creador — nunca
  /// en lo que ve el kiosko ni ningún tercero.
  final String? token;

  /// Tampoco viaja en lo que ve el kiosko/tercero -- lo resuelve el
  /// backend (ListarInvitaciones) solo para el listado del propio creador,
  /// para poder "replicar" esta invitación sin volver a teclear el
  /// teléfono del invitado (ver invitar_tab_view._replicarInvitacion).
  final String? telefono;

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
    this.motivo = '',
    this.token,
    this.telefono,
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
      motivo: json['motivo'] as String? ?? '',
      token: json['token'] as String?,
      telefono: json['telefono'] as String?,
    );
  }
}

/// Una fila de GET /personas/me/invitaciones/contactos — alguien a quien ya
/// se invitó antes desde esta cuenta, para "invitar de nuevo" sin volver a
/// teclear teléfono y nombre.
class ContactoFrecuenteModel {
  final int personaId;
  final String nombre;
  final String telefono;
  final String titular;
  final int destinoId;

  ContactoFrecuenteModel({
    required this.personaId,
    required this.nombre,
    required this.telefono,
    required this.titular,
    required this.destinoId,
  });

  factory ContactoFrecuenteModel.fromJson(Map<String, dynamic> json) {
    return ContactoFrecuenteModel(
      personaId: json['persona_id'] as int,
      nombre: json['nombre'] as String? ?? '',
      telefono: json['telefono'] as String? ?? '',
      titular: json['titular'] as String? ?? '',
      destinoId: json['destino_id'] as int,
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
  // true cuando esta invitación es la que enroló a quien la recibe como
  // invitado frecuente (entra por rostro/QR de ahí en adelante) -- distinta
  // de un pase normal de un solo uso.
  final bool permiteReconocimientoFacial;

  InvitacionRecibidaModel({
    required this.id,
    required this.tipo,
    required this.titular,
    required this.casaDestino,
    required this.nombreInvita,
    this.expiresAt,
    required this.createdAt,
    this.permiteReconocimientoFacial = false,
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
      permiteReconocimientoFacial: json['permite_reconocimiento_facial'] as bool? ?? false,
    );
  }
}
