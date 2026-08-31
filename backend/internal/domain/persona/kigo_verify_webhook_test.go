package persona

import (
	"bytes"
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/gin-gonic/gin"

	"kigo-autonomia-backend/internal/platform/ctxkeys"
)

// servidorKigoFalso responde el estado y la foto de un enrollment, que es lo
// que necesitan tanto el webhook como el polling para cerrar el flujo.
func servidorKigoFalso(t *testing.T, enrollmentID, status string, foto []byte) *httptest.Server {
	t.Helper()
	return httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.URL.Path {
		case "/v1/enrollments/" + enrollmentID:
			json.NewEncoder(w).Encode(map[string]any{"status": status})
		case "/v1/enrollments/" + enrollmentID + "/photo":
			w.Header().Set("Content-Type", "image/jpeg")
			w.Write(foto)
		default:
			t.Errorf("ruta inesperada: %s", r.URL.Path)
			w.WriteHeader(http.StatusNotFound)
		}
	}))
}

// El caso que tenía colgado el flujo entero: COMPLETED sólo se escribía desde
// el webhook, así que si la entrega no llegaba (o su firma no cuadraba) el
// polling contestaba PENDING para siempre y la app agotaba sus 3 minutos.
func TestConsultarEstadoKigoVerify_CompletaSinWebhook(t *testing.T) {
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
		PersonaID: p.ID, EnrollmentID: "enr-poll", WebhookSecret: "s",
		Status: "PENDING", ExpiresAt: time.Now().Add(time.Hour),
	})

	srv := servidorKigoFalso(t, "enr-poll", "COMPLETED", []byte("jpeg-falso"))
	defer srv.Close()

	tmpDir := t.TempDir()
	h := NewHandler(repo, nil, nil, nil, "", testQREd25519Seed, nil, nil, nil, nil, nil, tmpDir, "",
		KigoVerifyConfig{APIKey: "k", BaseURL: srv.URL, PublicURL: "https://autonomia.example"}, kigoRepo)

	router := gin.New()
	router.GET("/personas/me/kigo-verify/estado", func(c *gin.Context) {
		c.Set(ctxkeys.PersonaID, p.ID)
		c.Request = c.Request.WithContext(context.WithValue(c.Request.Context(), ctxkeys.PersonaID, p.ID))
		h.ConsultarEstadoKigoVerify(c)
	})

	req := httptest.NewRequest(http.MethodGet, "/personas/me/kigo-verify/estado?enrollment_id=enr-poll", nil)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	var resp struct {
		Status  string `json:"status"`
		FotoURL string `json:"foto_url"`
	}
	json.Unmarshal(w.Body.Bytes(), &resp)
	if resp.Status != "COMPLETED" {
		t.Fatalf("esperaba COMPLETED sin webhook, got %+v", resp)
	}
	if !strings.HasPrefix(resp.FotoURL, "https://autonomia.example/uploads/visitantes/") {
		t.Errorf("esperaba la foto servida desde PublicURL, got %q", resp.FotoURL)
	}

	guardado, _ := kigoRepo.FindByEnrollmentID("enr-poll")
	if guardado.Status != "COMPLETED" || guardado.FotoRostroURL != resp.FotoURL {
		t.Errorf("esperaba el enrollment cerrado en base, got %+v", guardado)
	}
}

// Un estado intermedio no cierra ni quema el enrollment: la app sigue esperando.
func TestConsultarEstadoKigoVerify_EstadoIntermedioSiguePendiente(t *testing.T) {
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
		PersonaID: p.ID, EnrollmentID: "enr-mid", WebhookSecret: "s",
		Status: "PENDING", ExpiresAt: time.Now().Add(time.Hour),
	})

	srv := servidorKigoFalso(t, "enr-mid", "LIVENESS_STARTED", nil)
	defer srv.Close()

	h := NewHandler(repo, nil, nil, nil, "", testQREd25519Seed, nil, nil, nil, nil, nil, t.TempDir(), "",
		KigoVerifyConfig{APIKey: "k", BaseURL: srv.URL}, kigoRepo)

	router := gin.New()
	router.GET("/estado", func(c *gin.Context) {
		c.Set(ctxkeys.PersonaID, p.ID)
		c.Request = c.Request.WithContext(context.WithValue(c.Request.Context(), ctxkeys.PersonaID, p.ID))
		h.ConsultarEstadoKigoVerify(c)
	})

	req := httptest.NewRequest(http.MethodGet, "/estado?enrollment_id=enr-mid", nil)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	var resp struct {
		Status string `json:"status"`
	}
	json.Unmarshal(w.Body.Bytes(), &resp)
	if resp.Status != "PENDING" {
		t.Fatalf("esperaba PENDING en LIVENESS_STARTED, got %+v", resp)
	}
	sinCambios, _ := kigoRepo.FindByEnrollmentID("enr-mid")
	if sinCambios.Status != "PENDING" {
		t.Errorf("un estado intermedio no debe cerrar el enrollment, got %q", sinCambios.Status)
	}
}

func TestWebhookKigoVerify_FirmaHMACHex(t *testing.T) {
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
		PersonaID: p.ID, EnrollmentID: "enr-hmac", WebhookSecret: "secreto-real",
		Status: "PENDING", ExpiresAt: time.Now().Add(time.Hour),
	})

	srv := servidorKigoFalso(t, "enr-hmac", "COMPLETED", []byte("jpeg-falso"))
	defer srv.Close()

	h := NewHandler(repo, nil, nil, nil, "", testQREd25519Seed, nil, nil, nil, nil, nil, t.TempDir(), "",
		KigoVerifyConfig{APIKey: "k", BaseURL: srv.URL, PublicURL: "https://autonomia.example"}, kigoRepo)

	router := gin.New()
	router.POST("/webhooks/kigo-verify", h.WebhookKigoVerify)

	body, _ := json.Marshal(map[string]string{"enrollment_id": "enr-hmac"})
	mac := hmac.New(sha256.New, []byte("secreto-real"))
	mac.Write(body)

	req := httptest.NewRequest(http.MethodPost, "/webhooks/kigo-verify", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-Kigo-Signature", "sha256="+hex.EncodeToString(mac.Sum(nil)))
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("esperaba 200 con firma HMAC valida, got %d: %s", w.Code, w.Body.String())
	}
	actualizado, _ := kigoRepo.FindByEnrollmentID("enr-hmac")
	if actualizado.Status != "COMPLETED" || actualizado.FotoRostroURL == "" {
		t.Fatalf("esperaba COMPLETED con foto guardada, got %+v", actualizado)
	}
}

func TestFirmaWebhookValida(t *testing.T) {
	const secreto = "secreto-real"
	cuerpo := []byte(`{"enrollment_id":"enr-1"}`)

	mac := hmac.New(sha256.New, []byte(secreto))
	mac.Write(cuerpo)
	digest := mac.Sum(nil)

	casos := []struct {
		nombre  string
		header  string
		valor   string
		cuerpo  []byte
		esperado bool
	}{
		{"hmac hex sin prefijo", "X-Kigo-Signature", hex.EncodeToString(digest), cuerpo, true},
		{"hmac hex con sha256=", "X-Kigo-Signature", "sha256=" + hex.EncodeToString(digest), cuerpo, true},
		{"hmac base64", "X-Kigo-Signature", base64.StdEncoding.EncodeToString(digest), cuerpo, true},
		{"hmac de otro cuerpo", "X-Kigo-Signature", hex.EncodeToString(digest), []byte(`{"enrollment_id":"otro"}`), false},
		{"firma basura", "X-Kigo-Signature", "no-es-una-firma", cuerpo, false},
		{"secreto plano compat", "X-Webhook-Secret", secreto, cuerpo, true},
		{"secreto plano equivocado", "X-Webhook-Secret", "otro", cuerpo, false},
	}

	for _, c := range casos {
		t.Run(c.nombre, func(t *testing.T) {
			headers := http.Header{}
			headers.Set(c.header, c.valor)
			if got := firmaWebhookValida(headers, c.cuerpo, secreto); got != c.esperado {
				t.Errorf("esperaba %v, got %v", c.esperado, got)
			}
		})
	}

	t.Run("sin headers de firma", func(t *testing.T) {
		if firmaWebhookValida(http.Header{}, cuerpo, secreto) {
			t.Error("una entrega sin firma no debe pasar")
		}
	})

	t.Run("secreto vacio", func(t *testing.T) {
		headers := http.Header{}
		headers.Set("X-Webhook-Secret", "")
		if firmaWebhookValida(headers, cuerpo, "") {
			t.Error("un enrollment sin secreto no debe aceptar ninguna firma")
		}
	})
}

// El webhook y el polling pueden cerrar el mismo enrollment a la vez. El
// segundo no debe pisar la foto del primero: los dos tienen que reportar la
// misma URL, o la app se queda con una que ya no es la guardada.
func TestMarcarCompletado_NoPisaLaFotoDelPrimero(t *testing.T) {
	db := setupTestDB(t)
	if err := db.AutoMigrate(&KigoVerifyEnrollment{}); err != nil {
		t.Fatalf("no se pudo migrar: %v", err)
	}
	kigoRepo := NewKigoVerifyRepository(db)

	e := &KigoVerifyEnrollment{
		PersonaID: 1, EnrollmentID: "enr-race", WebhookSecret: "s",
		Status: "PENDING", ExpiresAt: time.Now().Add(time.Hour),
	}
	kigoRepo.Crear(e)

	primera, err := kigoRepo.MarcarCompletado(e.ID, "https://x/primera.jpg")
	if err != nil || primera != "https://x/primera.jpg" {
		t.Fatalf("el primero debe quedarse con su foto, got %q err=%v", primera, err)
	}

	segunda, err := kigoRepo.MarcarCompletado(e.ID, "https://x/segunda.jpg")
	if err != nil {
		t.Fatalf("no esperaba error, got %v", err)
	}
	if segunda != "https://x/primera.jpg" {
		t.Errorf("el segundo debe recibir la foto ya guardada, got %q", segunda)
	}

	guardado, _ := kigoRepo.FindByEnrollmentID("enr-race")
	if guardado.FotoRostroURL != "https://x/primera.jpg" {
		t.Errorf("la foto en base no debe cambiar, got %q", guardado.FotoRostroURL)
	}
}
