/// Una fila de GET /personas/me/companeros-casa — deliberadamente angosto:
/// solo lo que el backend decide compartir entre residentes de la misma
/// casa (nunca teléfono, CURP ni foto).
class CompaneroCasa {
  final String nombreCompleto;

  /// 'residente' o 'invitado_frecuente' -- alguien con acceso recurrente
  /// prestado por un residente, no un residente real. Sin esto se veía en
  /// esta lista exactamente igual que un compañero de vivienda real.
  final String rol;

  CompaneroCasa({required this.nombreCompleto, this.rol = 'residente'});

  bool get esInvitadoFrecuente => rol == 'invitado_frecuente';

  factory CompaneroCasa.fromJson(Map<String, dynamic> json) {
    return CompaneroCasa(
      nombreCompleto: json['nombre_completo'] as String? ?? '',
      rol: json['rol'] as String? ?? 'residente',
    );
  }
}
