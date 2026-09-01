/// Modelo local que refleja el KioskoConfigResponse del backend.
/// Campos: tipo, foto_placa_visitante, foto_rostro_visitante, foto_placa_invitado,
/// foto_rostro_invitado, foto_ine_invitado (= ine_obligatorio_invitado),
/// tiempo_espera_seg, horario_inicio, horario_fin, mensaje_bienvenida,
/// auto_pass_habilitado, umbral_facial_pct, tiempo_exito_seg.
// Paleta de color del kiosko configurada desde el dashboard admin.
enum KioskoColorTema { oscuro, claro }

/// Tipo de acceso que atiende esta terminal. Decide qué flujo monta la app:
/// el peatonal (INE + rostro) o el vehicular (INE + rostro + placa).
/// Viene del backend en la misma config que el resto de los ajustes.
enum TipoKiosko { peatonal, vehicular }

class KioskoConfig {
  final TipoKiosko tipo;
  final bool fotoPlacaVisitante;
  final bool fotoRostroVisitante;
  final bool fotoIneVisitante;
  final List<String> pasosSinInvitacion;
  final bool fotoPlacaInvitado;
  final bool fotoRostroInvitado;
  final bool ineObligatorioInvitado;
  final int tiempoEsperaSeg;
  final String horarioInicio;
  final String horarioFin;
  final String mensajeBienvenida;
  final bool autoPassHabilitado;
  /// Porcentaje (0-100) de similitud coseno que se exige para dar por
  /// buena una cara en el match local. 85 = el 0.85 que antes estaba
  /// clavado en coincidencia_facial_local.dart.
  ///
  /// Es distinto del umbral de autopase, que vive solo en el backend: aquel
  /// decide si una entrada se aprueba sola, este decide si dos caras son la
  /// misma. Compartían campo hasta la migración 000058.
  final int umbralFacialPct;
  final int tiempoExitoSeg;
  final KioskoColorTema colorTema;
  final String idioma; // 'es' | 'en'
  /// Número del vigilante/admin para el botón "hablar con el administrador".
  /// Vacío = el botón no aparece (nada configurado).
  final String telefonoContacto;

  const KioskoConfig({
    this.tipo = TipoKiosko.peatonal,
    required this.fotoPlacaVisitante,
    required this.fotoRostroVisitante,
    this.fotoIneVisitante = false,
    this.pasosSinInvitacion = const ['ROSTRO', 'DESTINO'],
    required this.fotoPlacaInvitado,
    required this.fotoRostroInvitado,
    required this.ineObligatorioInvitado,
    required this.tiempoEsperaSeg,
    required this.horarioInicio,
    required this.horarioFin,
    required this.mensajeBienvenida,
    required this.autoPassHabilitado,
    required this.umbralFacialPct,
    this.tiempoExitoSeg = 5,
    this.colorTema = KioskoColorTema.oscuro,
    this.idioma = 'es',
    this.telefonoContacto = '',
  });

  factory KioskoConfig.fromJson(Map<String, dynamic> json) {
    final colorStr = json['color_kiosko'] as String? ?? 'oscuro';
    final tipoEnum = (json['tipo'] as String?) == 'VEHICULAR'
        ? TipoKiosko.vehicular
        : TipoKiosko.peatonal;

    final defaultPasos = tipoEnum == TipoKiosko.vehicular
        ? const ['PLACA', 'ROSTRO', 'DESTINO']
        : const ['ROSTRO', 'DESTINO'];

    final rawPasos = json['pasos_sin_invitacion'] as List<dynamic>?;
    final pasos = rawPasos != null
        ? rawPasos.map((e) => e.toString().toUpperCase()).toList()
        : defaultPasos;

    return KioskoConfig(
      tipo: tipoEnum,
      fotoPlacaVisitante: json['foto_placa_visitante'] as bool? ?? false,
      fotoRostroVisitante: json['foto_rostro_visitante'] as bool? ?? true,
      fotoIneVisitante: json['foto_ine_visitante'] as bool? ?? false,
      pasosSinInvitacion: pasos,
      fotoPlacaInvitado: json['foto_placa_invitado'] as bool? ?? false,
      fotoRostroInvitado: json['foto_rostro_invitado'] as bool? ?? false,
      ineObligatorioInvitado: json['foto_ine_invitado'] as bool? ?? false,
      tiempoEsperaSeg: json['tiempo_espera_seg'] as int? ?? 60,
      horarioInicio: json['horario_inicio'] as String? ?? '08:00',
      horarioFin: json['horario_fin'] as String? ?? '20:00',
      mensajeBienvenida: json['mensaje_bienvenida'] as String? ?? '',
      autoPassHabilitado: json['auto_pass_habilitado'] as bool? ?? false,
      umbralFacialPct: json['umbral_facial_pct'] as int? ?? 85,
      tiempoExitoSeg: json['tiempo_exito_seg'] as int? ?? 5,
      colorTema: colorStr == 'claro' ? KioskoColorTema.claro : KioskoColorTema.oscuro,
      idioma: json['idioma_kiosko'] as String? ?? 'es',
      telefonoContacto: json['telefono_contacto'] as String? ?? '',
    );
  }

  static KioskoConfig get defaults => const KioskoConfig(
        tipo: TipoKiosko.peatonal,
        fotoPlacaVisitante: false,
        fotoRostroVisitante: true,
        fotoIneVisitante: false,
        pasosSinInvitacion: ['ROSTRO', 'DESTINO'],
        fotoPlacaInvitado: false,
        fotoRostroInvitado: false,
        ineObligatorioInvitado: false,
        tiempoEsperaSeg: 60,
        horarioInicio: '08:00',
        horarioFin: '20:00',
        mensajeBienvenida: '',
        autoPassHabilitado: false,
        umbralFacialPct: 85,
        tiempoExitoSeg: 5,
        colorTema: KioskoColorTema.oscuro,
        idioma: 'es',
        telefonoContacto: '',
      );

  /// Copia con un teléfono de contacto distinto -- usado por
  /// KioskoConfigNotifier para rellenar el respaldo persistido cuando el
  /// arranque en frío no logra traer la config real del backend.
  KioskoConfig withTelefonoContacto(String telefono) => KioskoConfig(
        tipo: tipo,
        fotoPlacaVisitante: fotoPlacaVisitante,
        fotoRostroVisitante: fotoRostroVisitante,
        fotoIneVisitante: fotoIneVisitante,
        pasosSinInvitacion: pasosSinInvitacion,
        fotoPlacaInvitado: fotoPlacaInvitado,
        fotoRostroInvitado: fotoRostroInvitado,
        ineObligatorioInvitado: ineObligatorioInvitado,
        tiempoEsperaSeg: tiempoEsperaSeg,
        horarioInicio: horarioInicio,
        horarioFin: horarioFin,
        mensajeBienvenida: mensajeBienvenida,
        autoPassHabilitado: autoPassHabilitado,
        umbralFacialPct: umbralFacialPct,
        tiempoExitoSeg: tiempoExitoSeg,
        colorTema: colorTema,
        idioma: idioma,
        telefonoContacto: telefono,
      );
}
