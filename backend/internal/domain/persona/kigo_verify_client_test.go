package persona

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestCrearEnrollmentKigo(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/v1/enrollments" {
			t.Fatalf("esperaba /v1/enrollments, got %s", r.URL.Path)
		}
		if r.Header.Get("x-api-key") != "test-key" {
			t.Errorf("esperaba x-api-key='test-key', got %q", r.Header.Get("x-api-key"))
		}
		var body struct {
			ExternalRef string         `json:"external_ref"`
			WebhookURL  string         `json:"webhook_url"`
			RedirectURL string         `json:"redirect_url"`
			TTLHours    int            `json:"ttl_hours"`
			Metadata    map[string]any `json:"metadata"`
		}
		json.NewDecoder(r.Body).Decode(&body)
		if body.ExternalRef == "" || body.WebhookURL == "" {
			t.Errorf("esperaba external_ref y webhook_url no vacios, got %+v", body)
		}
		// Sin redirect_url, Kigo deja al usuario en su pantalla final y el
		// WebView de kigo-app nunca detecta el fin del flujo.
		if body.RedirectURL != RedirectURLPorDefecto {
			t.Errorf("esperaba redirect_url=%q, got %q", RedirectURLPorDefecto, body.RedirectURL)
		}
		if body.Metadata["phone"] != "+525500000001" {
			t.Errorf("esperaba metadata.phone verbatim, got %+v", body.Metadata)
		}
		json.NewEncoder(w).Encode(map[string]any{
			"enrollment_id":  "enr-123",
			"enrollment_url": "https://verify.kigo.dev/e/enr-123",
			"webhook_secret": "secreto-una-vez",
			"expires_at":     "2026-08-30T00:00:00Z",
			"status":         "PENDING",
		})
	}))
	defer srv.Close()

	cfg := KigoVerifyConfig{APIKey: "test-key", BaseURL: srv.URL, PublicURL: "https://autonomia.example"}
	enrollmentID, enrollmentURL, webhookSecret, expiresAt, err := crearEnrollmentKigo(
		context.Background(), cfg, "persona-1-abc", map[string]any{"phone": "+525500000001"})
	if err != nil {
		t.Fatalf("no esperaba error, got %v", err)
	}
	if enrollmentID != "enr-123" || enrollmentURL == "" || webhookSecret != "secreto-una-vez" {
		t.Errorf("respuesta inesperada: id=%q url=%q secret=%q", enrollmentID, enrollmentURL, webhookSecret)
	}
	if expiresAt.IsZero() {
		t.Error("esperaba expires_at parseado, got zero value")
	}
}

func TestConsultarEnrollmentKigo(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/v1/enrollments/enr-123" {
			t.Fatalf("esperaba /v1/enrollments/enr-123, got %s", r.URL.Path)
		}
		json.NewEncoder(w).Encode(map[string]any{"status": "LIVENESS_FAILED"})
	}))
	defer srv.Close()

	cfg := KigoVerifyConfig{APIKey: "test-key", BaseURL: srv.URL}
	status, err := consultarEnrollmentKigo(context.Background(), cfg, "enr-123")
	if err != nil {
		t.Fatalf("no esperaba error, got %v", err)
	}
	if status != "LIVENESS_FAILED" {
		t.Errorf("esperaba LIVENESS_FAILED, got %q", status)
	}
}

func TestDescargarFotoKigo(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/v1/enrollments/enr-123/photo" {
			t.Fatalf("esperaba /v1/enrollments/enr-123/photo, got %s", r.URL.Path)
		}
		w.Header().Set("Content-Type", "image/jpeg")
		w.Write([]byte("contenido-jpeg-falso"))
	}))
	defer srv.Close()

	cfg := KigoVerifyConfig{APIKey: "test-key", BaseURL: srv.URL}
	bytes, err := descargarFotoKigo(context.Background(), cfg, "enr-123")
	if err != nil {
		t.Fatalf("no esperaba error, got %v", err)
	}
	if string(bytes) != "contenido-jpeg-falso" {
		t.Errorf("contenido inesperado: %q", string(bytes))
	}
}
