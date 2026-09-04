package persona

import (
	"bytes"
	"context"
	"crypto/ed25519"
	"encoding/hex"
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

	h := NewHandler(repo, nil, nil, nil, "", testQREd25519Seed, nil, nil, nil, nil, nil, "", "", KigoVerifyConfig{}, nil, nil, nil)

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

	const qrEd25519Seed = testQREd25519Seed

	invitado := &Persona{Telefono: "+525500000099", Nombre: "Beto"}
	repo.Create(invitado)

	db.Create(&destinos.Destino{Model: gorm.Model{ID: 1}, TenantID: 1, Nombre: "Casa 5", Calle: "Roble", Numero: "5", Titular: "Ana"})
	personaInvitadaID := invitado.ID
	db.Create(&invitaciones.Invitacion{
		Model: gorm.Model{ID: 1}, TenantID: 1, Token: "tok-x", Titular: "Beto",
		ResidenteID: 1, DestinoID: 1, PersonaInvitadaID: &personaInvitadaID,
	})

	h := NewHandler(repo, nil, nil, nil, "", qrEd25519Seed, membresiaRepo, nil, invitacionRepo, visitaRepo, destinoRepo, "", "", KigoVerifyConfig{}, nil, nil, nil)

	router := gin.New()
	router.POST("/personas/verificar-qr", func(c *gin.Context) {
		// injectKioskoTestCtx ya está definida en kiosko_login_handler_test.go,
		// mismo paquete persona — no declarar una nueva.
		injectKioskoTestCtx(c, ctxkeys.TenantID, uint(1))
		injectKioskoTestCtx(c, ctxkeys.KioskoID, uint(1))
		h.VerificarQR(c)
	})

	seed, _ := hex.DecodeString(qrEd25519Seed)
	firma := FirmarPersonaID(invitado.ID, ed25519.NewKeyFromSeed(seed))
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

func TestVerificarQR_ClientIDRepetido_NoDuplicaVisita(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db := setupTestDB(t)
	if err := db.AutoMigrate(&visitas.Visita{}, &destinos.Destino{}, &invitaciones.Invitacion{}); err != nil {
		t.Fatalf("no se pudo migrar: %v", err)
	}
	// Este test hace dos requests HTTP secuenciales contra el mismo :memory:
	// sqlite — sin fijar el pool a una sola conexión, GORM puede abrir una
	// segunda conexión física que ve una base en memoria distinta (vacía),
	// dando "no such table" de forma no determinística.
	if sqlDB, err := db.DB(); err == nil {
		sqlDB.SetMaxOpenConns(1)
	}
	repo := NewRepository(db)
	membresiaRepo := residente.NewMembresiaRepository(db)
	invitacionRepo := invitaciones.NewRepository(db)
	visitaRepo := visitas.NewRepository(db)
	destinoRepo := destinos.NewRepository(db)

	invitado := &Persona{Telefono: "+525500000098", Nombre: "Carla"}
	repo.Create(invitado)

	db.Create(&destinos.Destino{Model: gorm.Model{ID: 1}, TenantID: 1, Nombre: "Casa 5", Calle: "Roble", Numero: "5", Titular: "Ana"})
	personaInvitadaID := invitado.ID
	db.Create(&invitaciones.Invitacion{
		Model: gorm.Model{ID: 1}, TenantID: 1, Token: "tok-y", Titular: "Carla",
		ResidenteID: 1, DestinoID: 1, PersonaInvitadaID: &personaInvitadaID,
	})

	h := NewHandler(repo, nil, nil, nil, "", testQREd25519Seed, membresiaRepo, nil, invitacionRepo, visitaRepo, destinoRepo, "", "", KigoVerifyConfig{}, nil, nil, nil)

	router := gin.New()
	router.POST("/personas/verificar-qr", func(c *gin.Context) {
		injectKioskoTestCtx(c, ctxkeys.TenantID, uint(1))
		injectKioskoTestCtx(c, ctxkeys.KioskoID, uint(1))
		h.VerificarQR(c)
	})

	seed, _ := hex.DecodeString(testQREd25519Seed)
	firma := FirmarPersonaID(invitado.ID, ed25519.NewKeyFromSeed(seed))

	hacerRequest := func() VerificarQRResponse {
		body, _ := json.Marshal(VerificarQRRequest{PersonaID: invitado.ID, Firma: firma, ClientID: "cliente-offline-1"})
		req := httptest.NewRequest(http.MethodPost, "/personas/verificar-qr", bytes.NewReader(body))
		req.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)
		if w.Code != http.StatusOK {
			t.Fatalf("esperaba 200, got %d: %s", w.Code, w.Body.String())
		}
		var resp VerificarQRResponse
		if err := json.Unmarshal(w.Body.Bytes(), &resp); err != nil {
			t.Fatalf("no se pudo parsear la respuesta: %v", err)
		}
		return resp
	}

	primera := hacerRequest()
	segunda := hacerRequest()

	if primera.VisitaID == nil || segunda.VisitaID == nil {
		t.Fatalf("esperaba VisitaID en ambas respuestas: primera=%v segunda=%v", primera.VisitaID, segunda.VisitaID)
	}
	if *primera.VisitaID != *segunda.VisitaID {
		t.Errorf("client_id repetido debe devolver la misma visita (%d), obtuvo %d", *primera.VisitaID, *segunda.VisitaID)
	}

	var conteo int64
	db.Model(&visitas.Visita{}).Where("persona_id = ?", invitado.ID).Count(&conteo)
	if conteo != 1 {
		t.Errorf("esperaba exactamente 1 Visita creada, hay %d", conteo)
	}
}

func TestListarCompanerosCasa(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db := setupTestDB(t)
	repo := NewRepository(db)
	membresiaRepo := residente.NewMembresiaRepository(db)

	titular := &Persona{Telefono: "+525500000001", Nombre: "Ana", ApellidoPaterno: "Ruiz"}
	repo.Create(titular)
	db.Create(&residente.Membresia{PersonaID: titular.ID, TenantID: 1, CasaDestino: "Casa 1", Status: residente.ResidenteStatusActivo})

	familiar := &Persona{Telefono: "+525500000002", Nombre: "Beto", ApellidoPaterno: "Ruiz"}
	repo.Create(familiar)
	db.Create(&residente.Membresia{PersonaID: familiar.ID, TenantID: 1, CasaDestino: "Casa 1", Status: residente.ResidenteStatusActivo})

	h := NewHandler(repo, nil, nil, nil, "", testQREd25519Seed, membresiaRepo, nil, nil, nil, nil, "", "", KigoVerifyConfig{}, nil, nil, nil)

	router := gin.New()
	router.GET("/personas/me/companeros-casa", func(c *gin.Context) {
		c.Set(ctxkeys.PersonaID, titular.ID)
		c.Request = c.Request.WithContext(context.WithValue(c.Request.Context(), ctxkeys.PersonaID, titular.ID))
		h.ListarCompanerosCasa(c)
	})

	req := httptest.NewRequest(http.MethodGet, "/personas/me/companeros-casa?tenant_id=1", nil)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("esperaba 200, got %d: %s", w.Code, w.Body.String())
	}
	var resp struct {
		CasaDestino string `json:"casa_destino"`
		Companeros  []struct {
			NombreCompleto string `json:"nombre_completo"`
			Rol            string `json:"rol"`
		} `json:"companeros"`
	}
	if err := json.Unmarshal(w.Body.Bytes(), &resp); err != nil {
		t.Fatalf("respuesta no es JSON válido: %v", err)
	}
	if resp.CasaDestino != "Casa 1" {
		t.Errorf("esperaba casa_destino 'Casa 1', got %q", resp.CasaDestino)
	}
	if len(resp.Companeros) != 1 || resp.Companeros[0].NombreCompleto != "Beto Ruiz" {
		t.Fatalf("esperaba 1 compañero 'Beto Ruiz', got %+v", resp.Companeros)
	}
}

// Caso reportado: una Persona enrolada como invitado frecuente (Status
// activo, para que su rostro/QR funcionen en el kiosko, pero Rol
// invitado_frecuente, no residente) no debe poder ver acciones exclusivas
// de residente -- antes solo se checaba Status, nunca Rol.
func TestListarCompanerosCasa_InvitadoFrecuenteNoPuede(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db := setupTestDB(t)
	repo := NewRepository(db)
	membresiaRepo := residente.NewMembresiaRepository(db)

	p := &Persona{Telefono: "+525500000003", Nombre: "Carla", ApellidoPaterno: "Diaz"}
	repo.Create(p)
	db.Create(&residente.Membresia{
		PersonaID: p.ID, TenantID: 1, CasaDestino: "Casa 1",
		Status: residente.ResidenteStatusActivo, Rol: residente.RolInvitadoFrecuente,
	})

	h := NewHandler(repo, nil, nil, nil, "", testQREd25519Seed, membresiaRepo, nil, nil, nil, nil, "", "", KigoVerifyConfig{}, nil, nil, nil)

	router := gin.New()
	router.GET("/personas/me/companeros-casa", func(c *gin.Context) {
		c.Set(ctxkeys.PersonaID, p.ID)
		c.Request = c.Request.WithContext(context.WithValue(c.Request.Context(), ctxkeys.PersonaID, p.ID))
		h.ListarCompanerosCasa(c)
	})

	req := httptest.NewRequest(http.MethodGet, "/personas/me/companeros-casa?tenant_id=1", nil)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	if w.Code != http.StatusForbidden {
		t.Fatalf("esperaba 403 para un invitado frecuente, got %d: %s", w.Code, w.Body.String())
	}
}

func TestListarCompanerosCasa_SinMembresiaEnEseTenant(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db := setupTestDB(t)
	repo := NewRepository(db)
	membresiaRepo := residente.NewMembresiaRepository(db)

	p := &Persona{Telefono: "+525500000001", Nombre: "Ana", ApellidoPaterno: "Ruiz"}
	repo.Create(p)

	h := NewHandler(repo, nil, nil, nil, "", testQREd25519Seed, membresiaRepo, nil, nil, nil, nil, "", "", KigoVerifyConfig{}, nil, nil, nil)

	router := gin.New()
	router.GET("/personas/me/companeros-casa", func(c *gin.Context) {
		c.Set(ctxkeys.PersonaID, p.ID)
		c.Request = c.Request.WithContext(context.WithValue(c.Request.Context(), ctxkeys.PersonaID, p.ID))
		h.ListarCompanerosCasa(c)
	})

	req := httptest.NewRequest(http.MethodGet, "/personas/me/companeros-casa?tenant_id=99", nil)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	if w.Code != http.StatusForbidden {
		t.Fatalf("esperaba 403, got %d: %s", w.Code, w.Body.String())
	}
}

func TestListarCompanerosCasa_TenantIDInvalido(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db := setupTestDB(t)
	repo := NewRepository(db)
	membresiaRepo := residente.NewMembresiaRepository(db)
	h := NewHandler(repo, nil, nil, nil, "", testQREd25519Seed, membresiaRepo, nil, nil, nil, nil, "", "", KigoVerifyConfig{}, nil, nil, nil)

	router := gin.New()
	router.GET("/personas/me/companeros-casa", func(c *gin.Context) {
		c.Set(ctxkeys.PersonaID, uint(1))
		c.Request = c.Request.WithContext(context.WithValue(c.Request.Context(), ctxkeys.PersonaID, uint(1)))
		h.ListarCompanerosCasa(c)
	})

	req := httptest.NewRequest(http.MethodGet, "/personas/me/companeros-casa", nil)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	if w.Code != http.StatusBadRequest {
		t.Fatalf("esperaba 400, got %d: %s", w.Code, w.Body.String())
	}
}

// Caso reportado: una Persona enrolada como pendiente (todavia no aprobada
// por el admin) veia un PIN en la respuesta, aunque ese PIN no sirve para
// nada hasta que la membresia quede activa (FindActivasPorTenant filtra por
// status, ver kiosko_login_handler.go).
func TestPinVisible(t *testing.T) {
	if got := pinVisible(residente.ResidenteStatusActivo, residente.RolResidente, "12345"); got != "12345" {
		t.Errorf("esperaba el PIN visible para residente activo, got %q", got)
	}
	if got := pinVisible(residente.ResidenteStatusPendiente, residente.RolResidente, "12345"); got != "" {
		t.Errorf("esperaba PIN vacio para status pendiente, got %q", got)
	}
	if got := pinVisible(residente.ResidenteStatusRechazado, residente.RolResidente, "12345"); got != "" {
		t.Errorf("esperaba PIN vacio para status rechazado, got %q", got)
	}
	if got := pinVisible(residente.ResidenteStatusActivo, residente.RolInvitadoFrecuente, "12345"); got != "" {
		t.Errorf("esperaba PIN vacio para invitado frecuente (entra por rostro/QR, no PIN), got %q", got)
	}
}
