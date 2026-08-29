/// Resultado de POST /kioskos/:id/asistente/extraer-campo — valor null
/// significa que el LLM no entendió o tuvo baja confianza; el kiosko debe
/// seguir el flujo manual exacto de siempre en ese caso.
class CampoExtraido {
  final String? valor;
  final double confianza;

  CampoExtraido({this.valor, required this.confianza});

  factory CampoExtraido.fromJson(Map<String, dynamic> json) {
    return CampoExtraido(
      valor: json['valor'] as String?,
      confianza: (json['confianza'] as num?)?.toDouble() ?? 0,
    );
  }
}
