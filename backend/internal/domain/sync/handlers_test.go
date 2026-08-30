package sync

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"

	"kigo-autonomia-backend/internal/domain/destinos"
	"kigo-autonomia-backend/internal/domain/invitaciones"
	"kigo-autonomia-backend/internal/domain/persona"
	"kigo-autonomia-backend/internal/domain/residente"
	"kigo-autonomia-backend/internal/platform/ctxkeys"
)

func setupTestDB(t *testing.T) *gorm.DB {
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	if err != nil {
		t.Fatalf("no se pudo abrir sqlite en memoria: %v", err)
	}
	if err := db.AutoMigrate(&destinos.Destino{}, &persona.Persona{}, &residente.Membresia{}, &invitaciones.Invitacion{}); err != nil {
		t.Fatalf("no se pudo migrar: %v", err)
	}
	return db
}

func injectTestCtx(c *gin.Context, key string, val any) {
	c.Set(key, val)
	c.Request = c.Request.WithContext(context.WithValue(c.Request.Context(), key, val))
}

func TestGetSnapshot(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db := setupTestDB(t)

	db.Create(&destinos.Destino{TenantID: 1, Nombre: "Casa 1", Calle: "Roble", Tipo: "casa", Numero: "1", Titular: "Ana"})

	p := &persona.Persona{Telefono: "+525500000001", Nombre: "Ana", ApellidoPaterno: "Ruiz", Embedding: []float64{1.0, 0.0, 0.0}}
	db.Create(p)
	db.Create(&residente.Membresia{PersonaID: p.ID, TenantID: 1, CasaDestino: "Casa 1", Pin: "hash", Status: "activo"})

	pPendiente := &persona.Persona{Telefono: "+525500000002", Nombre: "Luis", ApellidoPaterno: "Gomez"}
	db.Create(pPendiente)
	db.Create(&residente.Membresia{PersonaID: pPendiente.ID, TenantID: 1, CasaDestino: "Casa 2", Pin: "hash2", Status: "pendiente"})

	db.Create(&invitaciones.Invitacion{TenantID: 1, Token: "tok-1", Titular: "Invitado", ResidenteID: 1, DestinoID: 1})
	db.Create(&destinos.Destino{TenantID: 2, Nombre: "Casa X", Calle: "Pino", Tipo: "casa", Numero: "9", Titular: "Otro"})

	destinoRepo := destinos.NewRepository(db)
	personaRepo := persona.NewRepository(db)
	invitacionRepo := invitaciones.NewRepository(db)
	h := NewHandler(destinoRepo, personaRepo, invitacionRepo)

	router := gin.New()
	router.GET("/kioskos/:id/sync/snapshot", func(c *gin.Context) {
		injectTestCtx(c, ctxkeys.TenantID, uint(1))
		injectTestCtx(c, ctxkeys.KioskoID, uint(1))
		h.GetSnapshot(c)
	})

	req := httptest.NewRequest(http.MethodGet, "/kioskos/1/sync/snapshot", nil)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("esperaba 200, got %d: %s", w.Code, w.Body.String())
	}

	var resp SnapshotResponse
	if err := json.Unmarshal(w.Body.Bytes(), &resp); err != nil {
		t.Fatalf("no se pudo parsear la respuesta: %v", err)
	}

	if len(resp.Destinos) != 1 {
		t.Errorf("esperaba 1 destino, got %d: %+v", len(resp.Destinos), resp.Destinos)
	}
	if len(resp.Residentes) != 1 {
		t.Errorf("esperaba 1 residente (solo la membresia activa), got %d: %+v", len(resp.Residentes), resp.Residentes)
	}
	if len(resp.Invitaciones) != 1 {
		t.Errorf("esperaba 1 invitacion, got %d: %+v", len(resp.Invitaciones), resp.Invitaciones)
	}
	if len(resp.Residentes) == 1 && resp.Residentes[0].CasaDestino != "Casa 1" {
		t.Errorf("residente con casa_destino inesperada: %+v", resp.Residentes[0])
	}
}

func TestGetSnapshot_ResidenteIncluyePersonaIDDistintoDeMembresiaID(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db := setupTestDB(t)

	db.Create(&destinos.Destino{TenantID: 1, Nombre: "Casa 1", Calle: "Roble", Tipo: "casa", Numero: "1", Titular: "Ana"})

	// Persona de relleno para que PersonaID y MembresiaID diverjan (cada
	// tabla tiene su propio contador autoincremental) — sin esto el test
	// no distinguiría un mapeo correcto de uno que confunde los dos IDs.
	relleno := &persona.Persona{Telefono: "+525500000000", Nombre: "Relleno"}
	db.Create(relleno)

	p := &persona.Persona{Telefono: "+525500000001", Nombre: "Ana", ApellidoPaterno: "Ruiz"}
	db.Create(p)
	membresia := &residente.Membresia{PersonaID: p.ID, TenantID: 1, CasaDestino: "Casa 1", Pin: "hash", Status: "activo"}
	db.Create(membresia)

	destinoRepo := destinos.NewRepository(db)
	personaRepo := persona.NewRepository(db)
	invitacionRepo := invitaciones.NewRepository(db)
	h := NewHandler(destinoRepo, personaRepo, invitacionRepo)

	router := gin.New()
	router.GET("/kioskos/:id/sync/snapshot", func(c *gin.Context) {
		injectTestCtx(c, ctxkeys.TenantID, uint(1))
		injectTestCtx(c, ctxkeys.KioskoID, uint(1))
		h.GetSnapshot(c)
	})

	req := httptest.NewRequest(http.MethodGet, "/kioskos/1/sync/snapshot", nil)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	var resp SnapshotResponse
	if err := json.Unmarshal(w.Body.Bytes(), &resp); err != nil {
		t.Fatalf("no se pudo parsear la respuesta: %v", err)
	}
	if len(resp.Residentes) != 1 {
		t.Fatalf("esperaba 1 residente, got %d", len(resp.Residentes))
	}
	if resp.Residentes[0].PersonaID != p.ID {
		t.Errorf("PersonaID = %d, esperaba %d", resp.Residentes[0].PersonaID, p.ID)
	}
	if resp.Residentes[0].ID != membresia.ID {
		t.Errorf("ID (MembresiaID) = %d, esperaba %d — no debe cambiar, sigue siendo el PK local", resp.Residentes[0].ID, membresia.ID)
	}
	if p.ID == membresia.ID {
		t.Fatal("el fixture no distingue PersonaID de MembresiaID — el test no prueba nada")
	}
}

func TestGetSnapshot_InvitacionIncluyePersonaInvitadaIDYPermiteReconocimiento(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db := setupTestDB(t)

	db.Create(&destinos.Destino{TenantID: 1, Nombre: "Casa 1", Calle: "Roble", Tipo: "casa", Numero: "1", Titular: "Ana"})

	invitado := &persona.Persona{Telefono: "+525500000099", Nombre: "Beto"}
	db.Create(invitado)
	db.Create(&invitaciones.Invitacion{
		TenantID: 1, Token: "tok-1", Titular: "Beto",
		ResidenteID: 1, DestinoID: 1,
		PersonaInvitadaID: &invitado.ID, PermiteReconocimientoFacial: true,
	})

	destinoRepo := destinos.NewRepository(db)
	personaRepo := persona.NewRepository(db)
	invitacionRepo := invitaciones.NewRepository(db)
	h := NewHandler(destinoRepo, personaRepo, invitacionRepo)

	router := gin.New()
	router.GET("/kioskos/:id/sync/snapshot", func(c *gin.Context) {
		injectTestCtx(c, ctxkeys.TenantID, uint(1))
		injectTestCtx(c, ctxkeys.KioskoID, uint(1))
		h.GetSnapshot(c)
	})

	req := httptest.NewRequest(http.MethodGet, "/kioskos/1/sync/snapshot", nil)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	var resp SnapshotResponse
	if err := json.Unmarshal(w.Body.Bytes(), &resp); err != nil {
		t.Fatalf("no se pudo parsear la respuesta: %v", err)
	}
	if len(resp.Invitaciones) != 1 {
		t.Fatalf("esperaba 1 invitacion, got %d", len(resp.Invitaciones))
	}
	inv := resp.Invitaciones[0]
	if inv.PersonaInvitadaID == nil || *inv.PersonaInvitadaID != invitado.ID {
		t.Errorf("PersonaInvitadaID no coincide: %+v", inv.PersonaInvitadaID)
	}
	if !inv.PermiteReconocimientoFacial {
		t.Error("esperaba PermiteReconocimientoFacial = true")
	}
}
