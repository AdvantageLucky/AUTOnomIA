package asistente

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"

	"kigo-autonomia-backend/internal/domain/destinos"
	"kigo-autonomia-backend/internal/domain/kiosko"
	"kigo-autonomia-backend/internal/platform/ctxkeys"
)

func setupAsistenteTestDB(t *testing.T) *gorm.DB {
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	if err != nil {
		t.Fatalf("no se pudo abrir sqlite en memoria: %v", err)
	}
	if err := db.AutoMigrate(&kiosko.Kiosko{}, &kiosko.KioskoConfig{}, &destinos.Destino{}); err != nil {
		t.Fatalf("no se pudo migrar: %v", err)
	}
	return db
}

func TestPreguntar_ConLLMDisponible(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db := setupAsistenteTestDB(t)
	kioskoRepo := kiosko.NewRepository(db)
	destinoRepo := destinos.NewRepository(db)

	db.Create(&kiosko.Kiosko{Model: gorm.Model{ID: 1}, TenantID: 1, Nombre: "K1", ClaveKiosko: "x", AdminID: 1})
	db.Create(&kiosko.KioskoConfig{KioskoID: 1, TenantID: 1, MensajeBienvenida: "Bienvenido a Las Palmas"})

	var promptRecibido string
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		var body struct {
			Prompt string `json:"prompt"`
		}
		json.NewDecoder(r.Body).Decode(&body)
		promptRecibido = body.Prompt
		json.NewEncoder(w).Encode(map[string]string{"content": "Necesitas tu INE vigente."})
	}))
	defer srv.Close()

	h := NewHandler(kioskoRepo, destinoRepo, srv.URL)

	router := gin.New()
	router.POST("/kioskos/:id/asistente/preguntar", func(c *gin.Context) {
		c.Set(ctxkeys.KioskoID, uint(1))
		c.Set(ctxkeys.TenantID, uint(1))
		c.Request = c.Request.WithContext(context.WithValue(c.Request.Context(), ctxkeys.KioskoID, uint(1)))
		h.Preguntar(c)
	})

	body, _ := json.Marshal(map[string]string{"pregunta": "¿qué documentos necesito?"})
	req := httptest.NewRequest(http.MethodPost, "/kioskos/1/asistente/preguntar", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("esperaba 200, got %d: %s", w.Code, w.Body.String())
	}
	var resp struct {
		Respuesta string `json:"respuesta"`
	}
	json.Unmarshal(w.Body.Bytes(), &resp)
	if resp.Respuesta != "Necesitas tu INE vigente." {
		t.Errorf("esperaba la respuesta del LLM, got %q", resp.Respuesta)
	}
	if !bytes.Contains([]byte(promptRecibido), []byte("Bienvenido a Las Palmas")) {
		t.Errorf("esperaba que el prompt incluyera el mensaje de bienvenida del KioskoConfig, got %q", promptRecibido)
	}
}

func TestPreguntar_LLMCaido_UsaFallback(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db := setupAsistenteTestDB(t)
	kioskoRepo := kiosko.NewRepository(db)
	destinoRepo := destinos.NewRepository(db)

	db.Create(&kiosko.KioskoConfig{KioskoID: 1, TenantID: 1})

	h := NewHandler(kioskoRepo, destinoRepo, "http://localhost:1") // puerto que nadie escucha

	router := gin.New()
	router.POST("/kioskos/:id/asistente/preguntar", func(c *gin.Context) {
		c.Set(ctxkeys.KioskoID, uint(1))
		c.Set(ctxkeys.TenantID, uint(1))
		c.Request = c.Request.WithContext(context.WithValue(c.Request.Context(), ctxkeys.KioskoID, uint(1)))
		h.Preguntar(c)
	})

	body, _ := json.Marshal(map[string]string{"pregunta": "¿qué documentos necesito?"})
	req := httptest.NewRequest(http.MethodPost, "/kioskos/1/asistente/preguntar", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("esperaba 200 incluso con LLM caido, got %d: %s", w.Code, w.Body.String())
	}
	var resp struct {
		Respuesta string `json:"respuesta"`
	}
	json.Unmarshal(w.Body.Bytes(), &resp)
	if resp.Respuesta == "" {
		t.Fatal("esperaba un mensaje de fallback no vacio")
	}
}
