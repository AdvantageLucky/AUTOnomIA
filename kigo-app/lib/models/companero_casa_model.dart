/// Una fila de GET /personas/me/companeros-casa — deliberadamente angosto:
/// solo lo que el backend decide compartir entre residentes de la misma
/// casa (nunca teléfono, CURP ni foto).
class CompaneroCasa {
  final String nombreCompleto;

  /// 'titular' · 'familiar', tal cual lo guarda el backend.
  final String rol;

  CompaneroCasa({required this.nombreCompleto, required this.rol});

  factory CompaneroCasa.fromJson(Map<String, dynamic> json) {
    return CompaneroCasa(
      nombreCompleto: json['nombre_completo'] as String? ?? '',
      rol: json['rol'] as String? ?? '',
    );
  }
}
