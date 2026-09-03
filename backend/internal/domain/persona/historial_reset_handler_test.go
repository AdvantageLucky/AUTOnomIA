package persona

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"

	"kigo-autonomia-backend/internal/domain/residente"
	"kigo-autonomia-backend/internal/domain/visitas"
	"kigo-autonomia-backend/internal/platform/ctxkeys"
)

// TestResetHistorialContacto_SoloAfectaMiCasa confirma el scope "SOLO LOS
// MIOS": el reset que pide un residente solo aplica a la casa de SU propia
// membresía, resuelta desde el tenant_id que manda en la query -- nunca a
// ciegas ni globalmente.
func TestResetHistorialContacto_SoloAfectaMiCasa(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db := setupTestDB(t)
	if err := db.AutoMigrate(&visitas.Visita{}, &visitas.HistorialReset{}, &residente.Membresia{}); err != nil {
		t.Fatalf("no se pudo migrar: %v", err)
	}
	repo := NewRepository(db)
	membresiaRepo := residente.NewMembresiaRepository(db)
	visitaRepo := visitas.NewRepository(db)

	residenteID := uint(1)
	if err := membresiaRepo.Create(&residente.Membresia{
		PersonaID: residenteID, TenantID: 1, CasaDestino: "Casa 1", Pin: "hash", Status: residente.ResidenteStatusActivo,
	}); err != nil {
		t.Fatalf("no se pudo crear membresia: %v", err)
	}

	contactoID := uint(42)
	if err := visitaRepo.Create(&visitas.Visita{
		TenantID: 1, Titular: "Ivan", CasaDestino: "Casa 1", PersonaID: &contactoID,
		Estado: visitas.EstadoAprobado, KioskoID: 1,
		TipoVisitante: visitas.TipoResidente, TipoDocumento: visitas.DocumentoPIN,
	}); err != nil {
		t.Fatalf("no se pudo crear la visita: %v", err)
	}

	h := NewHandler(repo, nil, nil, nil, "", testQREd25519Seed, membresiaRepo, nil, nil, visitaRepo, nil, "", "", KigoVerifyConfig{}, nil, nil, nil)

	router := gin.New()
	router.POST("/personas/contactos/:personaId/resetear-historial", func(c *gin.Context) {
		injectKioskoTestCtx(c, ctxkeys.PersonaID, residenteID)
		h.ResetHistorialContacto(c)
	})

	req := httptest.NewRequest(http.MethodPost, "/personas/contactos/42/resetear-historial?tenant_id=1", nil)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)
	if w.Code != http.StatusOK {
		t.Fatalf("esperaba 200, got %d: %s", w.Code, w.Body.String())
	}

	// El historial hacia Casa 1 (la del residente que reseteó) debe quedar
	// vacío; hacia cualquier otra casa, intacto.
	historialCasa1, err := visitaRepo.HistorialDeVisitante(
		visitas.Visita{TenantID: 1, PersonaID: &contactoID, CasaDestino: "Casa 1", TipoVisitante: visitas.TipoResidente, TipoDocumento: visitas.DocumentoPIN},
		70, visitas.ScoreIaFuentes{},
	)
	if err != nil {
		t.Fatalf("no esperaba error: %v", err)
	}
	if len(historialCasa1) != 0 {
		t.Errorf("esperaba historial vacío hacia Casa 1 tras el reset, got %d", len(historialCasa1))
	}
}
