package persona

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"strconv"
	"testing"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"

	"kigo-autonomia-backend/internal/domain/destinos"
	"kigo-autonomia-backend/internal/domain/invitaciones"
	"kigo-autonomia-backend/internal/domain/residente"
	"kigo-autonomia-backend/internal/domain/visitas"
	"kigo-autonomia-backend/internal/platform/ctxkeys"
)

// Bug reportado: un invitado frecuente (Membresia.Rol=invitado_frecuente,
// alguien a quien UN residente le dio acceso recurrente a SU casa) podía
// crear sus propias invitaciones y dar de alta a otros invitados
// frecuentes -- una escalada de privilegios que ningún residente autorizó.
// CrearInvitacion y CrearInvitadoFrecuente ahora exigen Rol=RolResidente,
// no solo Status=Activo.

func setupInvitadoFrecuenteTest(t *testing.T) (*Handler, *gorm.DB, *Persona, *Persona) {
	t.Helper()
	gin.SetMode(gin.TestMode)
	db := setupTestDB(t)
	if err := db.AutoMigrate(&visitas.Visita{}, &destinos.Destino{}, &invitaciones.Invitacion{}); err != nil {
		t.Fatalf("no se pudo migrar: %v", err)
	}
	repo := NewRepository(db)
	membresiaRepo := residente.NewMembresiaRepository(db)
	invitacionRepo := invitaciones.NewRepository(db)
	visitaRepo := visitas.NewRepository(db)
	destinoRepo := destinos.NewRepository(db)

	db.Create(&destinos.Destino{Model: gorm.Model{ID: 1}, TenantID: 1, Nombre: "Casa 101", Calle: "Roble", Numero: "101", Titular: "Ana"})

	residenteReal := &Persona{Telefono: "+525500000001", Nombre: "Ana"}
	repo.Create(residenteReal)
	db.Create(&residente.Membresia{
		PersonaID: residenteReal.ID, TenantID: 1, CasaDestino: "Casa 101",
		Status: residente.ResidenteStatusActivo, Rol: residente.RolResidente,
	})

	invitadoFrecuente := &Persona{Telefono: "+525500000002", Nombre: "Beto"}
	repo.Create(invitadoFrecuente)
	db.Create(&residente.Membresia{
		PersonaID: invitadoFrecuente.ID, TenantID: 1, CasaDestino: "Casa 101",
		Status: residente.ResidenteStatusActivo, Rol: residente.RolInvitadoFrecuente,
	})

	h := NewHandler(repo, nil, nil, nil, "", testQREd25519Seed, membresiaRepo, nil, invitacionRepo, visitaRepo, destinoRepo, "", "", KigoVerifyConfig{}, nil, nil, nil)
	return h, db, residenteReal, invitadoFrecuente
}

func TestCrearInvitacion_InvitadoFrecuenteNoPuedeInvitar(t *testing.T) {
	h, db, _, invitadoFrecuente := setupInvitadoFrecuenteTest(t)

	router := gin.New()
	router.POST("/personas/me/invitaciones", func(c *gin.Context) {
		c.Set(ctxkeys.PersonaID, invitadoFrecuente.ID)
		c.Request = c.Request.WithContext(context.WithValue(c.Request.Context(), ctxkeys.PersonaID, invitadoFrecuente.ID))
		h.CrearInvitacion(c)
	})

	body, _ := json.Marshal(CrearInvitacionPersonaRequest{
		TenantID: 1, TelefonoInvitado: "+525500000003", Tipo: invitaciones.InvitacionPersonal, DestinoID: 1,
	})
	req := httptest.NewRequest(http.MethodPost, "/personas/me/invitaciones", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	if w.Code != http.StatusForbidden {
		t.Fatalf("esperaba 403 (invitado frecuente no puede invitar), got %d: %s", w.Code, w.Body.String())
	}

	var count int64
	db.Model(&invitaciones.Invitacion{}).Count(&count)
	if count != 0 {
		t.Errorf("no debió crearse ninguna invitación, got %d", count)
	}
}

func TestCrearInvitadoFrecuente_InvitadoFrecuenteNoPuedeEncadenar(t *testing.T) {
	h, db, _, invitadoFrecuente := setupInvitadoFrecuenteTest(t)

	router := gin.New()
	router.POST("/personas/me/invitados-frecuentes", func(c *gin.Context) {
		c.Set(ctxkeys.PersonaID, invitadoFrecuente.ID)
		c.Request = c.Request.WithContext(context.WithValue(c.Request.Context(), ctxkeys.PersonaID, invitadoFrecuente.ID))
		h.CrearInvitadoFrecuente(c)
	})

	body, _ := json.Marshal(CrearInvitadoFrecuenteRequest{
		TenantID: 1, TelefonoInvitado: "+525500000004",
	})
	req := httptest.NewRequest(http.MethodPost, "/personas/me/invitados-frecuentes", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	if w.Code != http.StatusForbidden {
		t.Fatalf("esperaba 403 (invitado frecuente no puede dar de alta a otro), got %d: %s", w.Code, w.Body.String())
	}

	var count int64
	db.Model(&residente.Membresia{}).Where("rol = ?", residente.RolInvitadoFrecuente).Count(&count)
	if count != 1 {
		t.Errorf("esperaba que siguiera existiendo solo el invitado frecuente original, got %d", count)
	}
}

func TestCrearInvitacion_ResidenteRealSiPuedeInvitar(t *testing.T) {
	h, db, residenteReal, _ := setupInvitadoFrecuenteTest(t)

	router := gin.New()
	router.POST("/personas/me/invitaciones", func(c *gin.Context) {
		c.Set(ctxkeys.PersonaID, residenteReal.ID)
		c.Request = c.Request.WithContext(context.WithValue(c.Request.Context(), ctxkeys.PersonaID, residenteReal.ID))
		h.CrearInvitacion(c)
	})

	body, _ := json.Marshal(CrearInvitacionPersonaRequest{
		TenantID: 1, TelefonoInvitado: "+525500000005", Tipo: invitaciones.InvitacionPersonal, DestinoID: 1,
	})
	req := httptest.NewRequest(http.MethodPost, "/personas/me/invitaciones", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	if w.Code != http.StatusCreated {
		t.Fatalf("esperaba 201 (un residente real sí puede invitar), got %d: %s", w.Code, w.Body.String())
	}

	var count int64
	db.Model(&invitaciones.Invitacion{}).Count(&count)
	if count != 1 {
		t.Errorf("esperaba 1 invitación creada, got %d", count)
	}
}

// Caso reportado: el invitado frecuente "eliminaba" la invitación con la
// que lo enrolaron desde "Recibidas", pero su membresía (el acceso
// recurrente en sí) seguía activa -- en Ajustes/Mi QR seguía viéndose como
// enrolado en ese centro. Eliminar esa invitación en particular debe
// también revocar el acceso que ella otorgó.
func TestEliminarInvitacionRecibida_RevocaMembresiaDeInvitadoFrecuente(t *testing.T) {
	h, db, residenteReal, invitadoFrecuente := setupInvitadoFrecuenteTest(t)

	invitadoID := invitadoFrecuente.ID
	inv := &invitaciones.Invitacion{
		TenantID: 1, Token: "tok-enrolamiento", Titular: "Beto", ResidenteID: residenteReal.ID, DestinoID: 1,
		PersonaInvitadaID: &invitadoID, PermiteReconocimientoFacial: true,
	}
	if err := db.Create(inv).Error; err != nil {
		t.Fatalf("no se pudo crear la invitación: %v", err)
	}

	router := gin.New()
	router.DELETE("/personas/me/invitaciones/recibidas/:id", func(c *gin.Context) {
		c.Set(ctxkeys.PersonaID, invitadoFrecuente.ID)
		c.Request = c.Request.WithContext(context.WithValue(c.Request.Context(), ctxkeys.PersonaID, invitadoFrecuente.ID))
		h.EliminarInvitacionRecibida(c)
	})

	req := httptest.NewRequest(http.MethodDelete, "/personas/me/invitaciones/recibidas/"+itoa(inv.ID), nil)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("esperaba 200, got %d: %s", w.Code, w.Body.String())
	}

	var m residente.Membresia
	err := db.Where("persona_id = ? AND tenant_id = ?", invitadoFrecuente.ID, 1).First(&m).Error
	if !errors.Is(err, gorm.ErrRecordNotFound) {
		t.Errorf("esperaba que la membresía de invitado frecuente quedara revocada (soft-delete), got err=%v, m=%+v", err, m)
	}
}

func itoa(id uint) string {
	return strconv.FormatUint(uint64(id), 10)
}
