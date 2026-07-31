/// Modelo local que refleja el KioskoConfigResponse del backend.
/// Campos: foto_placa_visitante, foto_rostro_visitante, foto_placa_invitado,
/// foto_rostro_invitado, foto_ine_invitado (= ine_obligatorio_invitado),
/// tiempo_espera_min, horario_inicio, horario_fin, mensaje_bienvenida,
/// auto_pass_habilitado, umbral_confianza_visitas.
class KioskoConfig {
  final bool fotoPlacaVisitante;
  final bool fotoRostroVisitante;
  final bool fotoPlacaInvitado;
  final bool fotoRostroInvitado;
  final bool ineObligatorioInvitado;
  final int tiempoEsperaMin;
  final String horarioInicio;
  final String horarioFin;
  final String mensajeBienvenida;
  final bool autoPassHabilitado;
  final int umbralConfianzaVisitas;

  const KioskoConfig({
    required this.fotoPlacaVisitante,
    required this.fotoRostroVisitante,
    required this.fotoPlacaInvitado,
    required this.fotoRostroInvitado,
    required this.ineObligatorioInvitado,
    required this.tiempoEsperaMin,
    required this.horarioInicio,
    required this.horarioFin,
    required this.mensajeBienvenida,
    required this.autoPassHabilitado,
    required this.umbralConfianzaVisitas,
  });

  factory KioskoConfig.fromJson(Map<String, dynamic> json) {
    return KioskoConfig(
      fotoPlacaVisitante: json['foto_placa_visitante'] as bool? ?? false,
      fotoRostroVisitante: json['foto_rostro_visitante'] as bool? ?? true,
      fotoPlacaInvitado: json['foto_placa_invitado'] as bool? ?? false,
      fotoRostroInvitado: json['foto_rostro_invitado'] as bool? ?? false,
      ineObligatorioInvitado: json['foto_ine_invitado'] as bool? ?? false,
      tiempoEsperaMin: json['tiempo_espera_min'] as int? ?? 15,
      horarioInicio: json['horario_inicio'] as String? ?? '08:00',
      horarioFin: json['horario_fin'] as String? ?? '20:00',
      mensajeBienvenida: json['mensaje_bienvenida'] as String? ?? '',
      autoPassHabilitado: json['auto_pass_habilitado'] as bool? ?? false,
      umbralConfianzaVisitas: json['umbral_confianza_visitas'] as int? ?? 80,
    );
  }

  static KioskoConfig get defaults => const KioskoConfig(
        fotoPlacaVisitante: false,
        fotoRostroVisitante: true,
        fotoPlacaInvitado: false,
        fotoRostroInvitado: false,
        ineObligatorioInvitado: false,
        tiempoEsperaMin: 15,
        horarioInicio: '08:00',
        horarioFin: '20:00',
        mensajeBienvenida: '',
        autoPassHabilitado: false,
        umbralConfianzaVisitas: 80,
      );
}
