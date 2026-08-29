package visitas

import (
	"context"
	"fmt"
	"strings"

	"kigo-autonomia-backend/internal/platform/llmclient"
)

const systemPromptVisitas = "Eres un asistente de seguridad en caseta residencial. Genera un resumen breve (máximo 2 oraciones) en español para el guardia de caseta sobre este visitante. Sé directo y objetivo."

// GenerarResumen convierte un ScoreContexto en texto narrativo en español.
// Primero intenta consultar el servidor LLM (soporta endpoints /completion y /v1/chat/completions).
// Si el LLM está apagado o falla, devuelve un resumen heurístico claro y determinista basado en el
// ScoreContexto — el texto siempre es utilizable, pero el error no-nil le avisa al caller que la
// llamada al LLM falló de verdad (a diferencia de "no había LLM configurado", que no es un error).
func GenerarResumen(ctx context.Context, llmURL string, s ScoreContexto) (string, error) {
	if strings.TrimSpace(llmURL) != "" {
		resumen, err := llmclient.Completar(ctx, strings.TrimSpace(llmURL), systemPromptVisitas, construirPrompt(s))
		if err == nil && strings.TrimSpace(resumen) != "" {
			return strings.TrimSpace(resumen), nil
		}
		if err == nil {
			err = fmt.Errorf("el LLM respondió vacío")
		}
		return s.AScoreIA().GenerarResumenHeuristico(), err
	}
	return s.AScoreIA().GenerarResumenHeuristico(), nil
}

func construirPrompt(s ScoreContexto) string {
	var anomalias []string
	if s.AnomaliaMatricula {
		anomalias = append(anomalias, "la matrícula es diferente a visitas anteriores")
	}
	if s.CambioModalidad {
		anomalias = append(anomalias, "solía venir con invitación QR y esta vez llegó sin ella")
	}
	if s.HorarioInusual {
		anomalias = append(anomalias, "el horario de llegada es inusual para este visitante")
	}
	if s.RechazadoPrevio {
		anomalias = append(anomalias, "tiene rechazos previos registrados")
	}
	if s.OCRSospechoso {
		anomalias = append(
			anomalias,
			"la CURP o clave de elector no pasan validación estructural (posible error de OCR)",
		)
	}

	historial := fmt.Sprintf("Ha visitado %d veces.", s.VecesVisitado)
	if s.VecesVisitado == 0 {
		historial = "Es la primera visita registrada."
	}

	confianza := ""
	if s.Confiable {
		confianza = " Es un visitante de alta confianza (múltiples aprobaciones consecutivas sin incidencias)."
	}

	anomaliasTexto := "No se detectaron anomalías."
	if len(anomalias) > 0 {
		anomaliasTexto = "Anomalías detectadas: " + strings.Join(anomalias, "; ") + "."
	}

	return fmt.Sprintf(`### Instrucción
Eres un asistente de seguridad. Genera un resumen breve (máximo 3 oraciones) en español para el guardia de caseta sobre este visitante. Sé directo y objetivo.

### Datos del visitante
%s%s %s

### Resumen
`, historial, confianza, anomaliasTexto)
}
