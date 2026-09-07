/// Una fila de GET /personas/me/destinos — casa/unidad de un tenant, con
/// su ID real (necesario para crear una invitación, a diferencia del
/// listado público de solo-nombres que usa el onboarding).
class DestinoModel {
  final int id;
  final String nombre;

  DestinoModel({required this.id, required this.nombre});

  factory DestinoModel.fromJson(Map<String, dynamic> json) {
    return DestinoModel(id: json['id'] as int, nombre: json['nombre'] as String);
  }
}
