/// Un factor del análisis de confianza — mismo shape que FactorScore en el
/// backend (internal/domain/visitas/score.go). El backend ya filtra la
/// lista a solo lo que es seguro mostrarle a un residente (ver
/// FiltrarScoreParaResidente): nunca llegan aquí factores que comparen
/// contra el historial del visitante en otras casas del fraccionamiento.
class FactorScoreModel {
  final String clave;
  final String etiqueta;
  final String detalle;
  final int impacto;
  final String tipo; // 'positivo' | 'negativo' | 'faltante'

  FactorScoreModel({
    required this.clave,
    required this.etiqueta,
    required this.detalle,
    required this.impacto,
    required this.tipo,
  });

  factory FactorScoreModel.fromJson(Map<String, dynamic> json) {
    return FactorScoreModel(
      clave: json['clave'] as String? ?? '',
      etiqueta: json['etiqueta'] as String? ?? '',
      detalle: json['detalle'] as String? ?? '',
      impacto: json['impacto'] as int? ?? 0,
      tipo: json['tipo'] as String? ?? '',
    );
  }
}

/// El score de confianza de una visita, ya recortado por el backend a lo
/// que un residente puede ver de una entrada dirigida a su propia casa.
class ScoreIaModel {
  final int confianzaPct;
  final String nivelConfianza; // 'alta' | 'media' | 'baja'
  final List<FactorScoreModel> factores;

  ScoreIaModel({
    required this.confianzaPct,
    required this.nivelConfianza,
    required this.factores,
  });

  factory ScoreIaModel.fromJson(Map<String, dynamic> json) {
    final rawFactores = json['factores'] as List<dynamic>?;
    return ScoreIaModel(
      confianzaPct: json['confianza_pct'] as int? ?? 0,
      nivelConfianza: json['nivel_confianza'] as String? ?? '',
      factores: rawFactores == null
          ? []
          : rawFactores
              .cast<Map<String, dynamic>>()
              .map(FactorScoreModel.fromJson)
              .toList(),
    );
  }
}
