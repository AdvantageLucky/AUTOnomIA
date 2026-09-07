/// Una fila de la respuesta de GET /personas/me/membresias — la Membresia
/// más reciente de la Persona (se asume una sola activa a la vez, ver
/// spec 2026-08-17-kigo-app-rediseno-design.md §8).
class MembresiaActual {
  final int id;
  final int tenantId;
  final String centroNombre;
  final String casaDestino;
  final String status;
  // 'residente' o 'invitado_frecuente' -- un invitado frecuente entra por
  // rostro/QR, no vive en el centro. La UI no debe presentárselo como si
  // fuera un residente inscrito (ver settings_view.dart).
  final String rol;

  bool get esResidente => rol == 'residente';

  /// PIN de 5 dígitos que genera el backend al crear la membresía — la
  /// persona ya no lo elige y no cambia. Se muestra en "Mi QR". Vacío para
  /// un invitado frecuente (entra por rostro/QR, no por PIN).
  final String pin;

  MembresiaActual({
    required this.id,
    required this.tenantId,
    required this.centroNombre,
    required this.casaDestino,
    required this.status,
    this.rol = 'residente',
    required this.pin,
  });

  factory MembresiaActual.fromJson(Map<String, dynamic> json) {
    return MembresiaActual(
      id: json['id'] as int,
      tenantId: json['tenant_id'] as int,
      centroNombre: json['centro_nombre'] as String? ?? '',
      casaDestino: json['casa_destino'] as String,
      status: json['status'] as String,
      rol: json['rol'] as String? ?? 'residente',
      pin: json['pin'] as String? ?? '',
    );
  }
}
