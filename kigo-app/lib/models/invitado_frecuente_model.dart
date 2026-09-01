/// Una fila de GET /personas/me/invitados-frecuentes -- alguien a quien un
/// residente de la casa le dio acceso recurrente por reconocimiento facial
/// (Membresia.Rol = invitado_frecuente en el backend). Entra por rostro
/// igual que un residente; el rol solo cambia permisos, no el mecanismo.
class InvitadoFrecuenteModel {
  final int id;
  final String nombre;
  final String telefono;

  InvitadoFrecuenteModel({
    required this.id,
    required this.nombre,
    required this.telefono,
  });

  factory InvitadoFrecuenteModel.fromJson(Map<String, dynamic> json) {
    return InvitadoFrecuenteModel(
      id: json['id'] as int,
      nombre: json['nombre'] as String? ?? '',
      telefono: json['telefono'] as String? ?? '',
    );
  }
}
