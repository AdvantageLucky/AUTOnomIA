package visitas

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
)

type llmRequest struct {
	Prompt      string   `json:"prompt"`
	NPredict    int      `json:"n_predict"`
	Temperature float64  `json:"temperature"`
	Stop        []string `json:"stop"`
}

type llmResponse struct {
	Content string `json:"content"`
}

// GenerarResumen convierte un ScoreContexto en texto narrativo en español
// usando el servidor llama.cpp en llmUrl. Respeta el ctx para timeout.
func GenerarResumen(ctx context.Context, llmUrl string, s ScoreContexto) (string, error) {
	prompt := construirPrompt(s)

	body, _ := json.Marshal(llmRequest{
		Prompt:      prompt,
		NPredict:    120,
		Temperature: 0.3,
		Stop:        []string{"\n\n", "###"},
	})

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, llmUrl+"/completion", bytes.NewReader(body))
	if err != nil {
		return "", err
	}
	req.Header.Set("Content-Type", "application/json")

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("llm status %d", resp.StatusCode)
	}

	var result llmResponse
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return "", err
	}
	return result.Content, nil
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
		anomalias = append(anomalias, "la CURP o clave de elector no pasan validación estructural (posible error de OCR)")
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
