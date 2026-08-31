package visitas

import (
	"context"
	"encoding/json"
	"log"
	"time"

	"kigo-autonomia-backend/internal/platform/ctxkeys"
)

// AnalizarYGuardarInformativo corre el análisis de patrones (resumen del LLM
// + heurísticas de anomalía) de una visita cuyo Estado ya quedó decidido por
// una verificación fuerte (PIN de residente, reconocimiento facial,
// invitación válida, QR personal) — a diferencia del walk-in (RegisterVisita
// en handlers.go), aquí el análisis nunca toca el Estado. Intervenida se
// marca según si se detectó una anomalía, no según un cambio de estado (que
// aquí nunca ocurre), para que el badge/filtro "Revisada por IA" del
// dashboard siga siendo útil en estos flujos también.
//
// Pensada para lanzarse en una goroutine después de responder al cliente,
// igual que el análisis de RegisterVisita — nunca se llama en el camino
// síncrono de ningún handler.
func AnalizarYGuardarInformativo(repo *Repository, tenantID uint, v Visita, llmURL string) {
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	asyncCtx := context.WithValue(ctx, ctxkeys.TenantID, tenantID)
	asyncRepo := repo.WithContext(asyncCtx)

	cfg, err := asyncRepo.GetKioskoConfig(v.KioskoID)
	if err != nil {
		return
	}

	historial, err := asyncRepo.HistorialDeVisitante(v)
	if err != nil {
		return
	}
	var historialPrevio []Visita
	for _, vh := range historial {
		if vh.ID != v.ID {
			historialPrevio = append(historialPrevio, vh)
		}
	}

	sc := AnalizarVisita(historialPrevio, v, evidenciaEsperadaDe(cfg, v))
	resumen, err := GenerarResumen(ctx, llmURL, sc, v)
	if err != nil {
		log.Printf("visita %d: LLM falló, usando resumen heurístico: %v", v.ID, err)
	}

	tieneAnomalias := sc.AnomaliaMatricula || sc.CambioModalidad || sc.HorarioInusual ||
		sc.RechazadoPrevio || sc.OCRSospechoso

	scoreIA, _ := json.Marshal(sc.AScoreIA())
	if err := asyncRepo.GuardarAnalisisIA(v.ID, resumen, scoreIA, nil, tieneAnomalias); err != nil {
		log.Printf("GuardarAnalisisIA visita %d: %v", v.ID, err)
	}
}
