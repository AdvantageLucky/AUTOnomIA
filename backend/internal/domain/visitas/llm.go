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

// GenerarResumen convierte un ScoreContexto en texto narrativo en español.
// Primero intenta consultar el servidor LLM (soporta endpoints /completion y /v1/chat/completions).
// Si el LLM está apagado o falla, devuelve un resumen heurístico claro y determinista basado en el ScoreContexto.
func GenerarResumen(ctx context.Context, llmURL string, s ScoreContexto) (string, error) {
	if strings.TrimSpace(llmURL) != "" {
		resumen, err := llamarLLM(ctx, strings.TrimSpace(llmURL), s)
		if err == nil && strings.TrimSpace(resumen) != "" {
			return strings.TrimSpace(resumen), nil
		}
	}
	return s.AScoreIA().GenerarResumenHeuristico(), nil
}

func llamarLLM(ctx context.Context, llmURL string, s ScoreContexto) (string, error) {
	baseURL := strings.TrimRight(llmURL, "/")
	prompt := construirPrompt(s)

	// Intento 1: Endpoint nativo llama.cpp /completion
	body, _ := json.Marshal(llmRequest{
		Prompt:      prompt,
		NPredict:    120,
		Temperature: 0.3,
		Stop:        []string{"\n\n", "###"},
	})

	req, err := http.NewRequestWithContext(
		ctx,
		http.MethodPost,
		baseURL+"/completion",
		bytes.NewReader(body),
	)
	if err == nil {
		req.Header.Set("Content-Type", "application/json")
		resp, err := http.DefaultClient.Do(req)
		if err == nil {
			defer resp.Body.Close()
			if resp.StatusCode == http.StatusOK {
				var result llmResponse
				if err := json.NewDecoder(resp.Body).Decode(&result); err == nil && strings.TrimSpace(result.Content) != "" {
					return limpiarResumenLLM(result.Content), nil
				}
			}
		}
	}

	// Intento 2: Endpoint estándar OpenAI /v1/chat/completions
	chatBody, _ := json.Marshal(map[string]any{
		"messages": []map[string]string{
			{"role": "system", "content": "Eres un asistente de seguridad en caseta residencial. Genera un resumen breve (máximo 2 oraciones) en español para el guardia de caseta sobre este visitante. Sé directo y objetivo."},
			{"role": "user", "content": prompt},
		},
		"max_tokens":  120,
		"temperature": 0.3,
	})

	reqChat, err := http.NewRequestWithContext(
		ctx,
		http.MethodPost,
		baseURL+"/v1/chat/completions",
		bytes.NewReader(chatBody),
	)
	if err == nil {
		reqChat.Header.Set("Content-Type", "application/json")
		respChat, err := http.DefaultClient.Do(reqChat)
		if err == nil {
			defer respChat.Body.Close()
			if respChat.StatusCode == http.StatusOK {
				var chatResult struct {
					Choices []struct {
						Message struct {
							Content string `json:"content"`
						} `json:"message"`
					} `json:"choices"`
				}
				if err := json.NewDecoder(respChat.Body).Decode(&chatResult); err == nil && len(chatResult.Choices) > 0 {
					return limpiarResumenLLM(chatResult.Choices[0].Message.Content), nil
				}
			}
		}
	}

	return "", fmt.Errorf("llm inaccesible")
}

func limpiarResumenLLM(texto string) string {
	res := strings.TrimSpace(texto)
	res = strings.TrimPrefix(res, "### Resumen")
	res = strings.TrimPrefix(res, "###")
	res = strings.TrimPrefix(res, "Resumen:")
	return strings.TrimSpace(res)
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
