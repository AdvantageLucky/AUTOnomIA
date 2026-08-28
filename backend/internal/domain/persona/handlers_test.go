package persona

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"

	"kigo-autonomia-backend/internal/domain/destinos"
	"kigo-autonomia-backend/internal/domain/invitaciones"
	"kigo-autonomia-backend/internal/domain/residente"
	"kigo-autonomia-backend/internal/domain/visitas"
	"kigo-autonomia-backend/internal/platform/ctxkeys"
)

func TestRegistrarDeviceToken(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db := setupTestDB(t)
	repo := NewRepository(db)
	p := &Persona{Telefono: "+525512345678"}
	repo.Create(p)

	h := NewHandler(repo, nil, nil, nil, "", "", nil, nil, nil, nil, nil, "")

	router := gin.New()
	router.POST("/personas/me/device-token", func(c *gin.Context) {
		c.Set(ctxkeys.PersonaID, p.ID)
		c.Request = c.Request.WithContext(context.WithValue(c.Request.Context(), ctxkeys.PersonaID, p.ID))
		h.RegistrarDeviceToken(c)
	})

	body, _ := json.Marshal(map[string]string{"device_token": "token-xyz"})
	req := httptest.NewRequest(http.MethodPost, "/personas/me/device-token", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("esperaba 200, got %d: %s", w.Code, w.Body.String())
	}

	found, _ := repo.FindByID(p.ID)
	if found.DeviceToken == nil || *found.DeviceToken != "token-xyz" {
		t.Errorf("esperaba device_token guardado, got %+v", found.DeviceToken)
	}
}

func TestVerificarQR_Invitado_PropagaPersonaID(t *testing.T) {
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

	const qrMasterSecret = "test-secret"

	invitado := &Persona{Telefono: "+525500000099", Nombre: "Beto"}
	repo.Create(invitado)

	db.Create(&destinos.Destino{Model: gorm.Model{ID: 1}, TenantID: 1, Nombre: "Casa 5", Calle: "Roble", Numero: "5", Titular: "Ana"})
	personaInvitadaID := invitado.ID
	db.Create(&invitaciones.Invitacion{
		Model: gorm.Model{ID: 1}, TenantID: 1, Token: "tok-x", Titular: "Beto",
		ResidenteID: 1, DestinoID: 1, PersonaInvitadaID: &personaInvitadaID,
	})

	h := NewHandler(repo, nil, nil, nil, "", qrMasterSecret, membresiaRepo, nil, invitacionRepo, visitaRepo, destinoRepo, "")

	router := gin.New()
	router.POST("/personas/verificar-qr", func(c *gin.Context) {
		// injectKioskoTestCtx ya está definida en kiosko_login_handler_test.go,
		// mismo paquete persona — no declarar una nueva.
		injectKioskoTestCtx(c, ctxkeys.TenantID, uint(1))
		injectKioskoTestCtx(c, ctxkeys.KioskoID, uint(1))
		h.VerificarQR(c)
	})

	firma := FirmarPersonaID(invitado.ID, qrMasterSecret)
	body, _ := json.Marshal(VerificarQRRequest{PersonaID: invitado.ID, Firma: firma})
	req := httptest.NewRequest(http.MethodPost, "/personas/verificar-qr", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("esperaba 200, got %d: %s", w.Code, w.Body.String())
	}

	var creada visitas.Visita
	if err := db.First(&creada).Error; err != nil {
		t.Fatalf("esperaba una visita creada: %v", err)
	}
	if creada.PersonaID == nil || *creada.PersonaID != invitado.ID {
		t.Errorf("esperaba PersonaID=%d en la visita creada, got %v", invitado.ID, creada.PersonaID)
	}
}
