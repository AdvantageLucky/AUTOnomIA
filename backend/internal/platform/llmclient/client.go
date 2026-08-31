package llmclient

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
)

type completionRequest struct {
	Prompt      string   `json:"prompt"`
	NPredict    int      `json:"n_predict"`
	Temperature float64  `json:"temperature"`
	Stop        []string `json:"stop"`
	// Penalizacion de repeticion. Un modelo local chico, con margen de tokens
	// y sin corte por linea en blanco, entra en bucle y repite la misma frase
	// hasta agotar el presupuesto — se vio en resumenes de entrada reales.
	// 1.15 sobre una ventana de 256 tokens rompe el bucle sin volver el texto
	// telegrafico.
	RepeatPenalty float64 `json:"repeat_penalty"`
	RepeatLastN   int     `json:"repeat_last_n"`
}

type completionResponse struct {
	Content string `json:"content"`
}

// tokensPorDefecto alcanza para las respuestas cortas del asistente del
// kiosko. Un resumen de entrada con factores y recomendaciones necesita más
// margen: para eso está CompletarConLimite.
const tokensPorDefecto = 120

// Completar intenta el endpoint nativo de llama.cpp (/completion) y, si falla,
// cae al endpoint estándar OpenAI-compatible (/v1/chat/completions). No decide
// fallback de negocio (heurística, mensaje fijo, etc.) — eso es responsabilidad
// de cada caller.
func Completar(ctx context.Context, baseURL, systemPrompt, prompt string) (string, error) {
	return CompletarConLimite(ctx, baseURL, systemPrompt, prompt, tokensPorDefecto)
}

// CompletarConLimite es Completar con un techo de tokens explícito, para
// respuestas que necesitan más espacio que el del asistente del kiosko.
func CompletarConLimite(ctx context.Context, baseURL, systemPrompt, prompt string, maxTokens int) (string, error) {
	base := strings.TrimRight(baseURL, "/")
	if maxTokens <= 0 {
		maxTokens = tokensPorDefecto
	}

	body, _ := json.Marshal(completionRequest{
		Prompt:        prompt,
		NPredict:      maxTokens,
		Temperature:   0.3,
		RepeatPenalty: 1.15,
		RepeatLastN:   256,
		// Se quitó el corte por línea en blanco: un resumen de varios párrafos
		// o con viñetas se truncaba en la primera. "###" sigue cortando el
		// encabezado que el modelo a veces intenta continuar por su cuenta.
		Stop: []string{"###"},
	})

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, base+"/completion", bytes.NewReader(body))
	if err == nil {
		req.Header.Set("Content-Type", "application/json")
		resp, err := http.DefaultClient.Do(req)
		if err == nil {
			defer resp.Body.Close()
			if resp.StatusCode == http.StatusOK {
				var result completionResponse
				if err := json.NewDecoder(resp.Body).Decode(&result); err == nil && strings.TrimSpace(result.Content) != "" {
					return limpiar(result.Content), nil
				}
			}
		}
	}

	chatBody, _ := json.Marshal(map[string]any{
		"messages": []map[string]string{
			{"role": "system", "content": systemPrompt},
			{"role": "user", "content": prompt},
		},
		"max_tokens":  maxTokens,
		"temperature": 0.3,
		// Equivalente de repeat_penalty para el endpoint OpenAI-compatible,
		// que no conoce ese parametro.
		"frequency_penalty": 0.3,
		"presence_penalty":  0.2,
	})

	reqChat, err := http.NewRequestWithContext(ctx, http.MethodPost, base+"/v1/chat/completions", bytes.NewReader(chatBody))
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
					return limpiar(chatResult.Choices[0].Message.Content), nil
				}
			}
		}
	}

	return "", fmt.Errorf("llm inaccesible")
}

func limpiar(texto string) string {
	res := strings.TrimSpace(texto)
	res = strings.TrimPrefix(res, "### Resumen")
	res = strings.TrimPrefix(res, "###")
	res = strings.TrimPrefix(res, "Resumen:")
	return strings.TrimSpace(res)
}
