package persona

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"

	"kigo-autonomia-backend/internal/domain/residente"
	"kigo-autonomia-backend/internal/domain/visitas"
	"kigo-autonomia-backend/internal/platform/ctxkeys"
)

func injectKioskoTestCtx(c *gin.Context, key string, val any) {
	c.Set(key, val)
	c.Request = c.Request.WithContext(context.WithValue(c.Request.Context(), key, val))
}

func TestLoginDesdeKiosko(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db := setupTestDB(t)
	if err := db.AutoMigrate(&visitas.Visita{}); err != nil {
		t.Fatalf("no se pudo migrar Visita: %v", err)
	}
	repo := NewRepository(db)
	visitaRepo := visitas.NewRepository(db)

	pinHash, _ := bcrypt.GenerateFromPassword([]byte("1234"), bcrypt.DefaultCost)
	p := &Persona{Telefono: "+525512345678", Nombre: "Ana", ApellidoPaterno: "Ruiz"}
	repo.Create(p)
	db.Create(&residente.Membresia{PersonaID: p.ID, TenantID: 1, CasaDestino: "Casa 1", Pin: string(pinHash), Status: "activo"})

	h := NewKioskoLoginHandler(repo, visitaRepo, db)

	router := gin.New()
	router.POST("/kioskos/:id/residentes/login", func(c *gin.Context) {
		injectKioskoTestCtx(c, ctxkeys.KioskoID, uint(1))
		injectKioskoTestCtx(c, ctxkeys.TenantID, uint(1))
		h.LoginDesdeKiosko(c)
	})

	body, _ := json.Marshal(map[string]string{"pin": "1234"})
	req := httptest.NewRequest(http.MethodPost, "/kioskos/1/residentes/login", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("esperaba 200, got %d: %s", w.Code, w.Body.String())
	}
	var resp map[string]string
	json.Unmarshal(w.Body.Bytes(), &resp)
	if resp["casa_destino"] != "Casa 1" {
		t.Errorf("esperaba casa_destino='Casa 1', got %+v", resp)
	}

	var count int64
	db.Model(&visitas.Visita{}).Count(&count)
	if count != 1 {
		t.Errorf("esperaba 1 visita creada, hay %d", count)
	}

	var creada visitas.Visita
	db.First(&creada)
	if creada.PersonaID == nil || *creada.PersonaID != p.ID {
		t.Errorf("esperaba PersonaID=%d en la visita creada, got %v", p.ID, creada.PersonaID)
	}
}

func TestVerificarRostroDesdeKiosko(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db := setupTestDB(t)
	if err := db.AutoMigrate(&visitas.Visita{}); err != nil {
		t.Fatalf("no se pudo migrar Visita: %v", err)
	}
	repo := NewRepository(db)
	visitaRepo := visitas.NewRepository(db)

	p := &Persona{Telefono: "+525512345678", Nombre: "Ana", ApellidoPaterno: "Ruiz", Embedding: []float64{1.0, 0.0, 0.0}}
	repo.Create(p)
	db.Create(&residente.Membresia{PersonaID: p.ID, TenantID: 1, CasaDestino: "Casa 1", Pin: "x", Status: "activo"})

	h := NewKioskoLoginHandler(repo, visitaRepo, db)

	router := gin.New()
	router.POST("/kioskos/:id/residentes/verificar-rostro", func(c *gin.Context) {
		injectKioskoTestCtx(c, ctxkeys.KioskoID, uint(1))
		injectKioskoTestCtx(c, ctxkeys.TenantID, uint(1))
		h.VerificarRostroDesdeKiosko(c)
	})

	body, _ := json.Marshal(map[string]any{"embedding": []float64{1.0, 0.0, 0.0}})
	req := httptest.NewRequest(http.MethodPost, "/kioskos/1/residentes/verificar-rostro", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("esperaba 200, got %d: %s", w.Code, w.Body.String())
	}

	var creada visitas.Visita
	db.First(&creada)
	if creada.PersonaID == nil || *creada.PersonaID != p.ID {
		t.Errorf("esperaba PersonaID=%d en la visita creada, got %v", p.ID, creada.PersonaID)
	}
}
