/// Una fila de GET /personas/me/companeros-casa — deliberadamente angosto:
/// solo lo que el backend decide compartir entre residentes de la misma
/// casa (nunca teléfono, CURP ni foto).
class CompaneroCasa {
  final String nombreCompleto;

  CompaneroCasa({required this.nombreCompleto});

  factory CompaneroCasa.fromJson(Map<String, dynamic> json) {
    return CompaneroCasa(
      nombreCompleto: json['nombre_completo'] as String? ?? '',
    );
  }
}
