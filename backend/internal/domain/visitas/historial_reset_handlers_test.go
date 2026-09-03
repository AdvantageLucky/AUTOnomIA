package visitas

import (
	"context"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"

	"kigo-autonomia-backend/internal/platform/ctxkeys"
)

// TestHistorialCorrelacionado_TraeElHistorialDeLaIdentidad confirma que el
// endpoint admin usa la correlación fuerte (PersonaID), no un cruce débil
// por CURP exacto.
func TestHistorialCorrelacionado_TraeElHistorialDeLaIdentidad(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db := setupHandlerTestDB(t)
	repo := NewRepository(db)
	h := NewHandler(repo, "/tmp", "", nil, nil)

	personaID := uint(42)
	v := &Visita{
		Model: gorm.Model{CreatedAt: time.Now()}, TenantID: 1, Titular: "Ivan", CasaDestino: "Casa 1",
		PersonaID: &personaID, Estado: EstadoAprobado, KioskoID: 1,
		TipoVisitante: TipoResidente, TipoDocumento: DocumentoPIN,
	}
	ctx := context.WithValue(context.Background(), ctxkeys.TenantID, uint(1))
	if err := repo.WithContext(ctx).Create(v); err != nil {
		t.Fatalf("no esperaba error creando la visita: %v", err)
	}

	router := gin.New()
	router.GET("/visitas/personas/:personaId/historial", func(c *gin.Context) {
		injectTestCtx(c, ctxkeys.TenantID, uint(1))
		injectTestCtx(c, ctxkeys.AdminID, uint(1))
		h.HistorialCorrelacionado(c)
	})

	req := httptest.NewRequest(http.MethodGet, "/visitas/personas/42/historial", nil)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("esperaba 200, got %d: %s", w.Code, w.Body.String())
	}
	if !strings.Contains(w.Body.String(), `"total":1`) {
		t.Errorf("esperaba total=1 en la respuesta, got %s", w.Body.String())
	}
}

// TestResetHistorialPersona_DejaElHistorialFuturoVacio confirma que el
// endpoint admin efectivamente crea el reset y que HistorialDeVisitante lo
// respeta después.
func TestResetHistorialPersona_DejaElHistorialFuturoVacio(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db := setupHandlerTestDB(t)
	repo := NewRepository(db)
	h := NewHandler(repo, "/tmp", "", nil, nil)

	personaID := uint(42)
	ctx := context.WithValue(context.Background(), ctxkeys.TenantID, uint(1))
	repoCtx := repo.WithContext(ctx)
	v := &Visita{
		Model: gorm.Model{CreatedAt: time.Now().Add(-24 * time.Hour)}, TenantID: 1, Titular: "Ivan",
		CasaDestino: "Casa 1", PersonaID: &personaID, Estado: EstadoAprobado, KioskoID: 1,
		TipoVisitante: TipoResidente, TipoDocumento: DocumentoPIN,
	}
	if err := repoCtx.Create(v); err != nil {
		t.Fatalf("no esperaba error creando la visita: %v", err)
	}

	router := gin.New()
	router.POST("/visitas/personas/:personaId/resetear-historial", func(c *gin.Context) {
		injectTestCtx(c, ctxkeys.TenantID, uint(1))
		injectTestCtx(c, ctxkeys.AdminID, uint(9))
		h.ResetHistorialPersona(c)
	})

	req := httptest.NewRequest(http.MethodPost, "/visitas/personas/42/resetear-historial", nil)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)
	if w.Code != http.StatusOK {
		t.Fatalf("esperaba 200, got %d: %s", w.Code, w.Body.String())
	}

	nueva := Visita{TenantID: 1, PersonaID: &personaID, CasaDestino: "Casa 2", TipoVisitante: TipoResidente, TipoDocumento: DocumentoPIN}
	historial, err := repoCtx.HistorialDeVisitante(nueva, 70, ScoreIaFuentes{})
	if err != nil {
		t.Fatalf("no esperaba error: %v", err)
	}
	if len(historial) != 0 {
		t.Errorf("esperaba historial vacío tras el reset admin (global), got %d", len(historial))
	}
}

