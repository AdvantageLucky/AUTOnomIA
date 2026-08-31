package visitas

import "math"

// maxVisitasEscaneadas acota la busqueda 1:N por rostro. Postgres plano no
// tiene indices de similitud (eso seria pgvector), asi que la comparacion se
// hace en memoria y hay que ponerle techo: con miles de entradas al mes, un
// scan completo por cada registro nuevo se vuelve el cuello de botella del
// analisis. Las mas recientes son ademas las que importan — un visitante que
// no aparece en las ultimas 2000 entradas del tenant no es un recurrente.
const maxVisitasEscaneadas = 2000

// similitudCoseno mide que tan parecidos son dos embeddings faciales.
// Regresa un valor en [-1, 1] (1 = identicos). -1 indica que no se pudo
// comparar (dimensiones distintas, vector vacio o de norma cero).
//
// Es la misma formula que persona.cosineSimilarity y que
// coincidencia_facial_local.dart en el kiosko. Se repite en vez de compartirse
// porque exportarla obligaria a que visitas dependa de persona solo por esto;
// son quince lineas de aritmetica que no van a divergir.
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
