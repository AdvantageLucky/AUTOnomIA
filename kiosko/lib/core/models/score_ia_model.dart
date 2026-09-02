/// Un factor del análisis de confianza -- mismo shape que FactorScore en el
/// backend (internal/domain/visitas/score.go). A diferencia de kigo-app
/// (donde el backend ya filtra la lista para un residente), aquí llega la
/// lista completa: este modelo solo lo usa la vista de detalle del
/// vigilante, protegida por PIN de operador -- nunca la pantalla que ve el
/// visitante.
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

/// El score de confianza de una visita, tal cual lo calcula el backend --
/// sin filtrar (ver comentario de [FactorScoreModel]).
class ScoreIaModel {
  final int confianzaPct;
  final String nivelConfianza; // 'alta' | 'media' | 'baja'
  final List<FactorScoreModel> factores;
  final List<String> recomendaciones;

  /// false cuando el resumen es el heurístico de respaldo (LLM apagado,
  /// sin configurar, o falló esta vez) -- el número/nivel de confianza es
  /// igual de confiable en ambos casos (es puramente determinista), lo que
  /// cambia es si hay redacción del LLM detrás del texto narrativo.
  final bool generadoPorIA;

  ScoreIaModel({
    required this.confianzaPct,
    required this.nivelConfianza,
    required this.factores,
    required this.recomendaciones,
    required this.generadoPorIA,
  });

  factory ScoreIaModel.fromJson(Map<String, dynamic> json) {
    final rawFactores = json['factores'] as List<dynamic>?;
    final rawRecs = json['recomendaciones'] as List<dynamic>?;
    return ScoreIaModel(
      confianzaPct: json['confianza_pct'] as int? ?? 0,
      nivelConfianza: json['nivel_confianza'] as String? ?? '',
      factores: rawFactores == null
          ? []
          : rawFactores.cast<Map<String, dynamic>>().map(FactorScoreModel.fromJson).toList(),
      recomendaciones: rawRecs == null ? [] : rawRecs.cast<String>(),
      generadoPorIA: json['generado_por_ia'] as bool? ?? false,
    );
  }
}
