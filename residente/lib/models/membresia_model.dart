/// Una fila de la respuesta de GET /personas/me/membresias — la Membresia
/// más reciente de la Persona (se asume una sola activa a la vez, ver
/// spec 2026-08-17-kigo-app-rediseno-design.md §8).
class MembresiaActual {
  final int id;
  final int tenantId;
  final String centroNombre;
  final String casaDestino;
  final String status;

  MembresiaActual({
    required this.id,
    required this.tenantId,
    required this.centroNombre,
    required this.casaDestino,
    required this.status,
  });

  factory MembresiaActual.fromJson(Map<String, dynamic> json) {
    return MembresiaActual(
      id: json['id'] as int,
      tenantId: json['tenant_id'] as int,
      centroNombre: json['centro_nombre'] as String? ?? '',
      casaDestino: json['casa_destino'] as String,
      status: json['status'] as String,
    );
  }
}
