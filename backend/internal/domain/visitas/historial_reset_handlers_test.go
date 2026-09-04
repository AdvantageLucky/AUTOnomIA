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

// Caso reportado: un visitante identificado solo por su INE (sin cuenta,
// sin invitación) no tenía forma de "olvidarse" -- ResetHistorialPersona
// exige un PersonaID, y esa identidad no tiene uno. ResetHistorialPorCURP
// ancla el reset al CURP en su lugar.
func TestResetHistorialPorCURP_DejaElHistorialFuturoVacio(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db := setupHandlerTestDB(t)
	repo := NewRepository(db)
	h := NewHandler(repo, "/tmp", "", nil, nil)

	ctx := context.WithValue(context.Background(), ctxkeys.TenantID, uint(1))
	repoCtx := repo.WithContext(ctx)
	v := &Visita{
		Model: gorm.Model{CreatedAt: time.Now().Add(-24 * time.Hour)}, TenantID: 1, Titular: "Beto",
		CasaDestino: "Casa 1", Curp: "BETO900101HDFXXX01", Estado: EstadoAprobado, KioskoID: 1,
		TipoVisitante: TipoSinInvitacion, TipoDocumento: DocumentoINE,
	}
	if err := repoCtx.Create(v); err != nil {
		t.Fatalf("no esperaba error creando la visita: %v", err)
	}

	router := gin.New()
	router.POST("/visitas/curp/:curp/resetear-historial", func(c *gin.Context) {
		injectTestCtx(c, ctxkeys.TenantID, uint(1))
		injectTestCtx(c, ctxkeys.AdminID, uint(9))
		h.ResetHistorialPorCURP(c)
	})

	req := httptest.NewRequest(http.MethodPost, "/visitas/curp/BETO900101HDFXXX01/resetear-historial", nil)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)
	if w.Code != http.StatusOK {
		t.Fatalf("esperaba 200, got %d: %s", w.Code, w.Body.String())
	}

	nueva := Visita{TenantID: 1, Curp: "BETO900101HDFXXX01", CasaDestino: "Casa 2", TipoVisitante: TipoSinInvitacion, TipoDocumento: DocumentoINE}
	historial, err := repoCtx.HistorialDeVisitante(nueva, 70, ScoreIaFuentes{Documento: true})
	if err != nil {
		t.Fatalf("no esperaba error: %v", err)
	}
	if len(historial) != 0 {
		t.Errorf("esperaba historial vacío tras el reset por CURP, got %d", len(historial))
	}
}

// TestListarIdentidades_AgrupaPorPersonaYPorCurpYOmiteSoloRostro cubre los
// 3 casos que la lista debe distinguir: identidad con PersonaID (residente
// o invitado con cuenta), identidad solo por CURP (visitante con INE, sin
// cuenta), y una visita sin PersonaID ni CURP (solo rostro) que debe
// quedar fuera porque no tiene identificador estable para resetear.
func TestListarIdentidades_AgrupaPorPersonaYPorCurpYOmiteSoloRostro(t *testing.T) {
	db := setupHandlerTestDB(t)
	// agregarIdentidades hace un SELECT crudo contra "personas" (no puede
	// importar el paquete persona: crearía un ciclo, persona ya importa
	// visitas) -- este stub mínimo basta para que el nombre se resuelva en
	// la prueba, sin acoplar el paquete al modelo real.
	if err := db.AutoMigrate(&personaStub{}); err != nil {
		t.Fatalf("no se pudo migrar el stub de personas: %v", err)
	}
	db.Create(&personaStub{ID: 42, Nombre: "Ana", ApellidoPaterno: "Residente"})

	repo := NewRepository(db)
	ctx := context.WithValue(context.Background(), ctxkeys.TenantID, uint(1))
	repoCtx := repo.WithContext(ctx)

	personaID := uint(42)
	visitas := []*Visita{
		{TenantID: 1, Titular: "Ana Residente", CasaDestino: "Casa 1", PersonaID: &personaID,
			Estado: EstadoAprobado, KioskoID: 1, TipoVisitante: TipoResidente, TipoDocumento: DocumentoPIN},
		{TenantID: 1, Titular: "Ana Residente", CasaDestino: "Casa 1", PersonaID: &personaID,
			Estado: EstadoAprobado, KioskoID: 1, TipoVisitante: TipoResidente, TipoDocumento: DocumentoPIN},
		{TenantID: 1, Titular: "Beto Visitante", CasaDestino: "Casa 2", Curp: "BETO900101HDFXXX01",
			Estado: EstadoAprobado, KioskoID: 1, TipoVisitante: TipoSinInvitacion, TipoDocumento: DocumentoINE},
		{TenantID: 1, Titular: "Desconocido", CasaDestino: "Casa 3",
			Estado: EstadoAprobado, KioskoID: 1, TipoVisitante: TipoSinInvitacion, TipoDocumento: DocumentoRostro},
	}
	for _, v := range visitas {
		if err := repoCtx.Create(v); err != nil {
			t.Fatalf("no esperaba error creando visita: %v", err)
		}
	}

	list, err := repoCtx.ListarIdentidadesConScore(1)
	if err != nil {
		t.Fatalf("no esperaba error: %v", err)
	}
	if len(list) != 2 {
		t.Fatalf("esperaba 2 identidades (persona + curp, sin la de solo-rostro), got %d: %+v", len(list), list)
	}

	var vioPersona, vioCurp bool
	for _, id := range list {
		if id.PersonaID != nil && *id.PersonaID == personaID {
			vioPersona = true
			if id.TotalVisitas != 2 {
				t.Errorf("esperaba 2 visitas agrupadas para la persona, got %d", id.TotalVisitas)
			}
		}
		if id.Curp == "BETO900101HDFXXX01" {
			vioCurp = true
			if id.TotalVisitas != 1 {
				t.Errorf("esperaba 1 visita para el CURP, got %d", id.TotalVisitas)
			}
		}
	}
	if !vioPersona || !vioCurp {
		t.Errorf("esperaba ver tanto la identidad por persona como la de CURP, got %+v", list)
	}
}

// personaStub es un modelo mínimo, solo para pruebas, que mapea a la misma
// tabla "personas" que agregarIdentidades consulta con SQL crudo -- ver el
// comentario en TestListarIdentidades_AgrupaPorPersonaYPorCurpYOmiteSoloRostro.
type personaStub struct {
	ID              uint `gorm:"primarykey"`
	Nombre          string
	ApellidoPaterno string
}

func (personaStub) TableName() string { return "personas" }

