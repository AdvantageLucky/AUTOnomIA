package persona

import "math"

// cosineSimilarity mide qué tan parecidos son dos embeddings faciales.
// Regresa un valor en [-1, 1] (1 = idénticos). -1 indica que no se pudo
// comparar (dimensiones distintas, vector vacío o de norma cero).
func cosineSimilarity(a, b []float64) float64 {
	if len(a) != len(b) || len(a) == 0 {
		return -1
	}

	var dot, normA, normB float64
	for i := range a {
		dot += a[i] * b[i]
		normA += a[i] * a[i]
		normB += b[i] * b[i]
	}
	if normA == 0 || normB == 0 {
		return -1
	}

	return dot / (math.Sqrt(normA) * math.Sqrt(normB))
}

// mejorCandidatoRostro recorre los candidatos y regresa el de mayor
// similitud contra el embedding capturado en vivo, junto con su score. Si
// candidatos está vacío regresa (nil, -1).
func mejorCandidatoRostro(candidatos []CandidatoKiosko, embedding []float64) (*CandidatoKiosko, float64) {
	var mejor *CandidatoKiosko
	mejorScore := -1.0

	for i := range candidatos {
		if len(candidatos[i].Embedding) == 0 {
			continue
		}
		score := cosineSimilarity(candidatos[i].Embedding, embedding)
		if score > mejorScore {
			mejorScore = score
			mejor = &candidatos[i]
		}
	}

	return mejor, mejorScore
}
