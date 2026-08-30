package persona

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/gin-gonic/gin"

	"kigo-autonomia-backend/internal/platform/ctxkeys"
)

func TestIniciarKigoVerify(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db := setupTestDB(t)
	if err := db.AutoMigrate(&KigoVerifyEnrollment{}); err != nil {
		t.Fatalf("no se pudo migrar: %v", err)
	}
	repo := NewRepository(db)
	kigoRepo := NewKigoVerifyRepository(db)

	p := &Persona{Telefono: "+525500000001"}
	repo.Create(p)

	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		json.NewEncoder(w).Encode(map[string]any{
			"enrollment_id": "enr-1", "enrollment_url": "https://verify.kigo.dev/e/enr-1",
			"webhook_secret": "s", "expires_at": "2026-08-30T00:00:00Z", "status": "PENDING",
		})
	}))
	defer srv.Close()

	h := NewHandler(repo, nil, nil, nil, "", testQREd25519Seed, nil, nil, nil, nil, nil, "", "",
		KigoVerifyConfig{APIKey: "k", BaseURL: srv.URL, PublicURL: "https://autonomia.example"}, kigoRepo)

	router := gin.New()
	router.POST("/personas/me/kigo-verify/iniciar", func(c *gin.Context) {
		c.Set(ctxkeys.PersonaID, p.ID)
		c.Request = c.Request.WithContext(context.WithValue(c.Request.Context(), ctxkeys.PersonaID, p.ID))
		h.IniciarKigoVerify(c)
	})

	req := httptest.NewRequest(http.MethodPost, "/personas/me/kigo-verify/iniciar", nil)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("esperaba 200, got %d: %s", w.Code, w.Body.String())
	}
	var resp struct {
		EnrollmentID  string `json:"enrollment_id"`
		EnrollmentURL string `json:"enrollment_url"`
	}
	json.Unmarshal(w.Body.Bytes(), &resp)
	if resp.EnrollmentID != "enr-1" || resp.EnrollmentURL == "" {
		t.Fatalf("respuesta inesperada: %+v", resp)
	}

	guardado, err := kigoRepo.FindByEnrollmentID("enr-1")
	if err != nil {
		t.Fatalf("esperaba el enrollment guardado: %v", err)
	}
	if guardado.PersonaID != p.ID || guardado.Status != "PENDING" {
		t.Errorf("guardado incorrecto: %+v", guardado)
	}
}

func TestConsultarEstadoKigoVerify_Completado(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db := setupTestDB(t)
	if err := db.AutoMigrate(&KigoVerifyEnrollment{}); err != nil {
		t.Fatalf("no se pudo migrar: %v", err)
	}
	repo := NewRepository(db)
	kigoRepo := NewKigoVerifyRepository(db)

	p := &Persona{Telefono: "+525500000001"}
	repo.Create(p)
	kigoRepo.Crear(&KigoVerifyEnrollment{
		PersonaID: p.ID, EnrollmentID: "enr-done", WebhookSecret: "s",
		Status: "COMPLETED", FotoRostroURL: "https://x/foto.jpg", ExpiresAt: time.Now().Add(time.Hour),
	})

	h := NewHandler(repo, nil, nil, nil, "", testQREd25519Seed, nil, nil, nil, nil, nil, "", "", KigoVerifyConfig{}, kigoRepo)

	router := gin.New()
	router.GET("/personas/me/kigo-verify/estado", func(c *gin.Context) {
		c.Set(ctxkeys.PersonaID, p.ID)
		c.Request = c.Request.WithContext(context.WithValue(c.Request.Context(), ctxkeys.PersonaID, p.ID))
		h.ConsultarEstadoKigoVerify(c)
	})

	req := httptest.NewRequest(http.MethodGet, "/personas/me/kigo-verify/estado?enrollment_id=enr-done", nil)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("esperaba 200, got %d: %s", w.Code, w.Body.String())
	}
	var resp struct {
		Status  string `json:"status"`
		FotoURL string `json:"foto_url"`
	}
	json.Unmarshal(w.Body.Bytes(), &resp)
	if resp.Status != "COMPLETED" || resp.FotoURL != "https://x/foto.jpg" {
		t.Fatalf("respuesta inesperada: %+v", resp)
	}
}

func TestConsultarEstadoKigoVerify_ExpiradoSinWebhook(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db := setupTestDB(t)
	if err := db.AutoMigrate(&KigoVerifyEnrollment{}); err != nil {
		t.Fatalf("no se pudo migrar: %v", err)
	}
	repo := NewRepository(db)
	kigoRepo := NewKigoVerifyRepository(db)

	p := &Persona{Telefono: "+525500000001"}
	repo.Create(p)
	kigoRepo.Crear(&KigoVerifyEnrollment{
		PersonaID: p.ID, EnrollmentID: "enr-exp", WebhookSecret: "s",
		Status: "PENDING", ExpiresAt: time.Now().Add(-time.Hour), // ya expiro
	})

	h := NewHandler(repo, nil, nil, nil, "", testQREd25519Seed, nil, nil, nil, nil, nil, "", "", KigoVerifyConfig{}, kigoRepo)

	router := gin.New()
	router.GET("/personas/me/kigo-verify/estado", func(c *gin.Context) {
		c.Set(ctxkeys.PersonaID, p.ID)
		c.Request = c.Request.WithContext(context.WithValue(c.Request.Context(), ctxkeys.PersonaID, p.ID))
		h.ConsultarEstadoKigoVerify(c)
	})

	req := httptest.NewRequest(http.MethodGet, "/personas/me/kigo-verify/estado?enrollment_id=enr-exp", nil)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	var resp struct {
		Status string `json:"status"`
	}
	json.Unmarshal(w.Body.Bytes(), &resp)
	if resp.Status != "FAILED" {
		t.Fatalf("esperaba FAILED por expiracion, got %+v", resp)
	}

	actualizado, _ := kigoRepo.FindByEnrollmentID("enr-exp")
	if actualizado.Status != "FAILED" {
		t.Errorf("esperaba que se persistiera FAILED, got %q", actualizado.Status)
	}
}

func TestConsultarEstadoKigoVerify_PendienteConsultaAKigo(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db := setupTestDB(t)
	if err := db.AutoMigrate(&KigoVerifyEnrollment{}); err != nil {
		t.Fatalf("no se pudo migrar: %v", err)
	}
	repo := NewRepository(db)
	kigoRepo := NewKigoVerifyRepository(db)

	p := &Persona{Telefono: "+525500000001"}
	repo.Create(p)
	kigoRepo.Crear(&KigoVerifyEnrollment{
		PersonaID: p.ID, EnrollmentID: "enr-pend", WebhookSecret: "s",
		Status: "PENDING", ExpiresAt: time.Now().Add(time.Hour),
	})

	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		json.NewEncoder(w).Encode(map[string]any{"status": "QUALITY_FAILED"})
	}))
	defer srv.Close()

	h := NewHandler(repo, nil, nil, nil, "", testQREd25519Seed, nil, nil, nil, nil, nil, "", "",
		KigoVerifyConfig{APIKey: "k", BaseURL: srv.URL}, kigoRepo)

	router := gin.New()
	router.GET("/personas/me/kigo-verify/estado", func(c *gin.Context) {
		c.Set(ctxkeys.PersonaID, p.ID)
		c.Request = c.Request.WithContext(context.WithValue(c.Request.Context(), ctxkeys.PersonaID, p.ID))
		h.ConsultarEstadoKigoVerify(c)
	})

	req := httptest.NewRequest(http.MethodGet, "/personas/me/kigo-verify/estado?enrollment_id=enr-pend", nil)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	var resp struct {
		Status string `json:"status"`
	}
	json.Unmarshal(w.Body.Bytes(), &resp)
	if resp.Status != "FAILED" {
		t.Fatalf("esperaba FAILED (Kigo reporto QUALITY_FAILED), got %+v", resp)
	}
}

func TestWebhookKigoVerify_FirmaValida(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db := setupTestDB(t)
	if err := db.AutoMigrate(&KigoVerifyEnrollment{}); err != nil {
		t.Fatalf("no se pudo migrar: %v", err)
	}
	repo := NewRepository(db)
	kigoRepo := NewKigoVerifyRepository(db)

	p := &Persona{Telefono: "+525500000001"}
	repo.Create(p)
	kigoRepo.Crear(&KigoVerifyEnrollment{
		PersonaID: p.ID, EnrollmentID: "enr-wh", WebhookSecret: "secreto-real",
		Status: "PENDING", ExpiresAt: time.Now().Add(time.Hour),
	})

	kigoSrv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte("foto-real"))
	}))
	defer kigoSrv.Close()

	tmpDir := t.TempDir()
	h := NewHandler(repo, nil, nil, nil, "", testQREd25519Seed, nil, nil, nil, nil, nil, tmpDir, "",
		KigoVerifyConfig{APIKey: "k", BaseURL: kigoSrv.URL}, kigoRepo)

	router := gin.New()
	router.POST("/webhooks/kigo-verify", h.WebhookKigoVerify)

	body, _ := json.Marshal(map[string]string{"enrollment_id": "enr-wh"})
	req := httptest.NewRequest(http.MethodPost, "/webhooks/kigo-verify", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-Webhook-Secret", "secreto-real")
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("esperaba 200, got %d: %s", w.Code, w.Body.String())
	}

	actualizado, _ := kigoRepo.FindByEnrollmentID("enr-wh")
	if actualizado.Status != "COMPLETED" || actualizado.FotoRostroURL == "" {
		t.Fatalf("esperaba COMPLETED con foto guardada, got %+v", actualizado)
	}
}

func TestWebhookKigoVerify_FirmaInvalida(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db := setupTestDB(t)
	if err := db.AutoMigrate(&KigoVerifyEnrollment{}); err != nil {
		t.Fatalf("no se pudo migrar: %v", err)
	}
	repo := NewRepository(db)
	kigoRepo := NewKigoVerifyRepository(db)

	p := &Persona{Telefono: "+525500000001"}
	repo.Create(p)
	kigoRepo.Crear(&KigoVerifyEnrollment{
		PersonaID: p.ID, EnrollmentID: "enr-bad", WebhookSecret: "secreto-real",
		Status: "PENDING", ExpiresAt: time.Now().Add(time.Hour),
	})

	h := NewHandler(repo, nil, nil, nil, "", testQREd25519Seed, nil, nil, nil, nil, nil, t.TempDir(), "", KigoVerifyConfig{}, kigoRepo)

	router := gin.New()
	router.POST("/webhooks/kigo-verify", h.WebhookKigoVerify)

	body, _ := json.Marshal(map[string]string{"enrollment_id": "enr-bad"})
	req := httptest.NewRequest(http.MethodPost, "/webhooks/kigo-verify", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-Webhook-Secret", "secreto-equivocado")
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	if w.Code != http.StatusUnauthorized {
		t.Fatalf("esperaba 401, got %d", w.Code)
	}

	sinCambios, _ := kigoRepo.FindByEnrollmentID("enr-bad")
	if sinCambios.Status != "PENDING" {
		t.Errorf("esperaba que el estado no cambiara, got %q", sinCambios.Status)
	}
}
