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
}

type completionResponse struct {
	Content string `json:"content"`
}

// Completar intenta el endpoint nativo de llama.cpp (/completion) y, si falla,
// cae al endpoint estándar OpenAI-compatible (/v1/chat/completions). No decide
// fallback de negocio (heurística, mensaje fijo, etc.) — eso es responsabilidad
// de cada caller.
func Completar(ctx context.Context, baseURL, systemPrompt, prompt string) (string, error) {
	base := strings.TrimRight(baseURL, "/")

	body, _ := json.Marshal(completionRequest{
		Prompt:      prompt,
		NPredict:    120,
		Temperature: 0.3,
		Stop:        []string{"\n\n", "###"},
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
		"max_tokens":  120,
		"temperature": 0.3,
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
