import 'dart:math';

/// Compara un embedding facial en vivo contra la lista de residentes
/// cacheados localmente — replica en Dart la misma comparacion 1:N por
/// similitud coseno que hace el backend (cosineSimilarity + mejorCandidatoRostro
/// en backend/internal/domain/persona/matching.go), necesaria porque en
/// modo offline no hay backend al que preguntarle.
///
/// Regresa el mapa del residente (mismo shape que entrega LocalCacheDb) si
/// el mejor score supera [umbral], o null si nadie califica.
Map<String, dynamic>? mejorCoincidenciaLocal(
  List<Map<String, dynamic>> residentes,
  List<double> embeddingVivo, {
  double umbral = 0.85,
}) {
  Map<String, dynamic>? mejor;
  double mejorScore = -1.0;

  for (final residente in residentes) {
    final embedding = (residente['embedding'] as List?)?.cast<double>() ?? const <double>[];
    if (embedding.isEmpty) continue;

    final score = _cosineSimilarity(embedding, embeddingVivo);
    if (score > mejorScore) {
      mejorScore = score;
      mejor = residente;
    }
  }

  if (mejor == null || mejorScore < umbral) return null;
  return mejor;
}

double _cosineSimilarity(List<double> a, List<double> b) {
  final n = min(a.length, b.length);
  double dot = 0, normA = 0, normB = 0;
  for (var i = 0; i < n; i++) {
    dot += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }
  if (normA == 0 || normB == 0) return 0;
  return dot / (sqrt(normA) * sqrt(normB));
}
