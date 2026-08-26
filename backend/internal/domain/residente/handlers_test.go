package residente

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

	"kigo-autonomia-backend/internal/domain/visitas"
	"kigo-autonomia-backend/internal/platform/ctxkeys"
)

func setupHandlerTestDB(t *testing.T) *gorm.DB {
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	if err != nil {
		t.Fatalf("no se pudo abrir sqlite en memoria: %v", err)
	}
	if err := db.AutoMigrate(&Residente{}, &visitas.Visita{}); err != nil {
		t.Fatalf("no se pudo migrar: %v", err)
	}
	embedding := FloatArray{1.0, 0.0, 0.0}
	db.Create(&Residente{
		TenantID: 1, Nombre: "Ana", ApellidoPaterno: "Ruiz", ApellidoMaterno: "Diaz",
		Pin: "hash", CasaDestino: "Casa 1", Status: ResidenteStatusActivo, Embedding: embedding,
	})
	return db
}

func injectTestCtx(c *gin.Context, key string, val any) {
	c.Set(key, val)
	c.Request = c.Request.WithContext(context.WithValue(c.Request.Context(), key, val))
}

func TestVerificarRostroDesdeKiosko_Idempotente(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db := setupHandlerTestDB(t)
	visitaRepo := visitas.NewRepository(db)
	h := NewHandler(NewRepository(db), nil, "", db, "/tmp", visitaRepo)

	router := gin.New()
	router.POST("/kioskos/:id/residentes/verificar-rostro", func(c *gin.Context) {
		injectTestCtx(c, ctxkeys.TenantID, uint(1))
		injectTestCtx(c, ctxkeys.KioskoID, uint(1))
		h.VerificarRostroDesdeKiosko(c)
	})

	payload, _ := json.Marshal(map[string]any{
		"embedding": []float64{1.0, 0.0, 0.0},
		"client_id": "mismo-uuid",
	})

	req1 := httptest.NewRequest(http.MethodPost, "/kioskos/1/residentes/verificar-rostro", bytes.NewReader(payload))
	req1.Header.Set("Content-Type", "application/json")
	w1 := httptest.NewRecorder()
	router.ServeHTTP(w1, req1)
	if w1.Code != http.StatusOK {
		t.Fatalf("primer POST: esperaba 200, got %d: %s", w1.Code, w1.Body.String())
	}

	req2 := httptest.NewRequest(http.MethodPost, "/kioskos/1/residentes/verificar-rostro", bytes.NewReader(payload))
	req2.Header.Set("Content-Type", "application/json")
	w2 := httptest.NewRecorder()
	router.ServeHTTP(w2, req2)
	if w2.Code != http.StatusOK {
		t.Fatalf("segundo POST (mismo client_id): esperaba 200, got %d: %s", w2.Code, w2.Body.String())
	}

	var count int64
	db.Model(&visitas.Visita{}).Count(&count)
	if count != 1 {
		t.Errorf("esperaba 1 sola visita creada, hay %d", count)
	}
}
