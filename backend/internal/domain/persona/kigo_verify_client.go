package persona

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"
)

// RedirectURLPorDefecto es la URL centinela a la que Kigo manda al usuario
// cuando termina el flujo web. No existe como sitio real: kigo-app la vigila
// desde su WebView y corta la navegacion en cuanto la ve (ver
// kigo_verify_webview_view.dart). Sin mandar redirect_url, Kigo deja al
// usuario en su propia pantalla final y el WebView nunca se cierra solo.
const RedirectURLPorDefecto = "https://autonomia.local/kigo-verify-listo"

// KigoVerifyConfig son las credenciales/endpoints del servicio externo Kigo
// Verify (Face Enrollment API) — ver docs/superpowers/specs/2026-08-29-kigo-verify-kigo-app-design.md.
type KigoVerifyConfig struct {
	APIKey      string
	BaseURL     string
	PublicURL   string // usado para construir el webhook_url que se manda a Kigo
	RedirectURL string // centinela de fin de flujo; vacio usa RedirectURLPorDefecto
}

func (cfg KigoVerifyConfig) webhookURL() string {
	return strings.TrimRight(cfg.PublicURL, "/") + "/api/v1/webhooks/kigo-verify"
}

func (cfg KigoVerifyConfig) redirectURL() string {
	if cfg.RedirectURL != "" {
		return cfg.RedirectURL
	}
	return RedirectURLPorDefecto
}

// crearEnrollmentKigo crea un enrollment nuevo en Kigo Verify. externalRef
// es nuestro identificador (no necesita ser único por Persona: una Persona
// puede reintentar y generar varios enrollments, cada uno con su propio
// externalRef). metadata se guarda tal cual del lado de Kigo y regresa
// verbatim en el webhook — sirve para reconciliar sin consultar la base.
func crearEnrollmentKigo(ctx context.Context, cfg KigoVerifyConfig, externalRef string, metadata map[string]any) (enrollmentID, enrollmentURL, webhookSecret string, expiresAt time.Time, err error) {
	payload := map[string]any{
		"external_ref": externalRef,
		"webhook_url":  cfg.webhookURL(),
		"redirect_url": cfg.redirectURL(),
		"ttl_hours":    24,
	}
	if len(metadata) > 0 {
		payload["metadata"] = metadata
	}
	body, _ := json.Marshal(payload)
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, strings.TrimRight(cfg.BaseURL, "/")+"/v1/enrollments", bytes.NewReader(body))
	if err != nil {
		return "", "", "", time.Time{}, err
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("x-api-key", cfg.APIKey)

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return "", "", "", time.Time{}, err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK && resp.StatusCode != http.StatusCreated {
		return "", "", "", time.Time{}, fmt.Errorf("kigo verify respondio %d al crear el enrollment", resp.StatusCode)
	}

	var result struct {
		EnrollmentID  string `json:"enrollment_id"`
		EnrollmentURL string `json:"enrollment_url"`
		WebhookSecret string `json:"webhook_secret"`
		ExpiresAt     string `json:"expires_at"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return "", "", "", time.Time{}, err
	}
	parsedExpiry, err := time.Parse(time.RFC3339, result.ExpiresAt)
	if err != nil {
		return "", "", "", time.Time{}, fmt.Errorf("expires_at invalido: %w", err)
	}
	return result.EnrollmentID, result.EnrollmentURL, result.WebhookSecret, parsedExpiry, nil
}

// consultarEnrollmentKigo consulta el estado actual en Kigo. No es solo un
// respaldo del webhook: es la unica ruta que no depende de que la entrega
// llegue, y por eso el handler de estado la usa para completar el flujo
// tambien (ver ConsultarEstadoKigoVerify).
func consultarEnrollmentKigo(ctx context.Context, cfg KigoVerifyConfig, enrollmentID string) (status string, err error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, strings.TrimRight(cfg.BaseURL, "/")+"/v1/enrollments/"+enrollmentID, nil)
	if err != nil {
		return "", err
	}
	req.Header.Set("x-api-key", cfg.APIKey)

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("kigo verify respondio %d al consultar el enrollment", resp.StatusCode)
	}

	var result struct {
		Status string `json:"status"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return "", err
	}
	return result.Status, nil
}

// descargarFotoKigo trae el JPEG de la foto del enrollment. Solo el backend
// llama esto (con su propia x-api-key) — la app nunca habla directo con Kigo.
func descargarFotoKigo(ctx context.Context, cfg KigoVerifyConfig, enrollmentID string) ([]byte, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, strings.TrimRight(cfg.BaseURL, "/")+"/v1/enrollments/"+enrollmentID+"/photo", nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("x-api-key", cfg.APIKey)

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("kigo verify respondio %d al descargar la foto", resp.StatusCode)
	}
	return io.ReadAll(resp.Body)
}
