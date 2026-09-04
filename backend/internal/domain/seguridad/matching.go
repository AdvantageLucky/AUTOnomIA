package seguridad

import "math"

// maxEventosEscaneados acota la busqueda 1:N por rostro -- mismo criterio y
// mismo limite que visitas.maxVisitasEscaneadas: Postgres plano no tiene
// indices de similitud (pgvector), asi que el scan es en memoria y hay que
// ponerle techo. Los eventos de seguridad recientes son los que importan
// para saber si es un intento repetido.
const maxEventosEscaneados = 2000

// similitudCoseno mide que tan parecidos son dos embeddings faciales.
// Regresa un valor en [-1, 1] (1 = identicos). -1 indica que no se pudo
// comparar (dimensiones distintas, vector vacio o de norma cero).
//
// Es la misma formula que visitas.similitudCoseno, persona.cosineSimilarity
// y coincidencia_facial_local.dart en el kiosko. Se repite en vez de
// compartirse por el mismo motivo documentado en visitas/matching.go: son
// quince lineas de aritmetica que no van a divergir, y exportarla obligaria
// a un import cruzado entre dominios solo por esto.
func similitudCoseno(a, b []float64) float64 {
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

// ContarCorrelacionados cuenta cuántos eventos ANTERIORES (con rostro) de
// este tenant superan el umbral de similitud contra [embedding] -- se llama
// una sola vez, al crear un evento nuevo (ver Handler.Reportar), para
// guardar el resultado en EventoSeguridad.IntentosPrevios.
func (r *Repository) ContarCorrelacionados(tenantID uint, embedding []float64, umbralPct int) (int, error) {
	if len(embedding) == 0 {
		return 0, nil
	}

	var candidatos []EventoSeguridad
	err := r.db.
		Where("tenant_id = ? AND embedding_rostro IS NOT NULL", tenantID).
		Order("created_at DESC").
		Limit(maxEventosEscaneados).
		Find(&candidatos).Error
	if err != nil {
		return 0, err
	}

	umbral := float64(umbralPct) / 100
	count := 0
	for _, c := range candidatos {
		if similitudCoseno(c.EmbeddingRostro, embedding) >= umbral {
			count++
		}
	}
	return count, nil
}
