package invitaciones

import (
	"context"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"

	"kigo-autonomia-backend/internal/domain/destinos"
	"kigo-autonomia-backend/internal/domain/kiosko"
	"kigo-autonomia-backend/internal/domain/visitas"
	"kigo-autonomia-backend/internal/platform/ctxkeys"
)

func setupHandlerTestDB(t *testing.T) *gorm.DB {
	db := setupTestDB(t)
	if err := db.AutoMigrate(&kiosko.KioskoConfig{}, &kiosko.Kiosko{}, &visitas.Visita{}, &destinos.Destino{}); err != nil {
		t.Fatalf("no se pudo migrar: %v", err)
	}
	db.Create(&kiosko.Kiosko{Model: gorm.Model{ID: 1}, TenantID: 1, Tipo: kiosko.KioskoPeatonal, Nombre: "K1", ClaveKiosko: "x", AdminID: 1})
	db.Create(&kiosko.KioskoConfig{KioskoID: 1, TenantID: 1})
	db.Model(&kiosko.KioskoConfig{}).Where("kiosko_id = ?", 1).Update("foto_rostro_invitado", false)
	db.Create(&destinos.Destino{Model: gorm.Model{ID: 1}, TenantID: 1, Nombre: "Casa 1", Calle: "Roble", Numero: "1", Titular: "Ana"})
	personaInvitadaID := uint(42)
	db.Create(&Invitacion{Model: gorm.Model{ID: 1}, TenantID: 1, Token: "tok-1", Titular: "Ana Invitada", ResidenteID: 1, DestinoID: 1, PersonaInvitadaID: &personaInvitadaID})
	return db
}

func injectTestCtx(c *gin.Context, key string, val any) {
	c.Set(key, val)
	c.Request = c.Request.WithContext(context.WithValue(c.Request.Context(), key, val))
}

func multipartBody(fields map[string]string) (string, *strings.Reader) {
	var b strings.Builder
	w := multipart.NewWriter(&b)
	for k, v := range fields {
		_ = w.WriteField(k, v)
	}
	w.Close()
	return w.FormDataContentType(), strings.NewReader(b.String())
}

func TestUsarInvitacion_Idempotente(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db := setupHandlerTestDB(t)
	h := NewHandler(NewRepository(db), db, "/tmp", visitas.NewRepository(db), "")

	router := gin.New()
	router.POST("/kioskos/:id/invitaciones/:token/usar", func(c *gin.Context) {
		injectTestCtx(c, ctxkeys.TenantID, uint(1))
		injectTestCtx(c, ctxkeys.KioskoID, uint(1))
		h.UsarInvitacion(c)
	})

	fields := map[string]string{"client_id": "mismo-uuid"}

	contentType, body := multipartBody(fields)
	req1 := httptest.NewRequest(http.MethodPost, "/kioskos/1/invitaciones/tok-1/usar", body)
	req1.Header.Set("Content-Type", contentType)
	w1 := httptest.NewRecorder()
	router.ServeHTTP(w1, req1)
	if w1.Code != http.StatusOK {
		t.Fatalf("primer POST: esperaba 200, got %d: %s", w1.Code, w1.Body.String())
	}

	contentType2, body2 := multipartBody(fields)
	req2 := httptest.NewRequest(http.MethodPost, "/kioskos/1/invitaciones/tok-1/usar", body2)
	req2.Header.Set("Content-Type", contentType2)
	w2 := httptest.NewRecorder()
	router.ServeHTTP(w2, req2)
	if w2.Code != http.StatusOK {
		t.Fatalf("segundo POST (mismo client_id): esperaba 200, got %d: %s", w2.Code, w2.Body.String())
	}

	var countVisitas int64
	db.Model(&visitas.Visita{}).Count(&countVisitas)
	if countVisitas != 1 {
		t.Errorf("esperaba 1 sola visita creada, hay %d", countVisitas)
	}

	var inv Invitacion
	db.First(&inv, 1)
	if inv.ConteoUsos != 1 {
		t.Errorf("esperaba ConteoUsos=1 (solo la primera llamada incrementa), got %d", inv.ConteoUsos)
	}

	var creada visitas.Visita
	db.First(&creada)
	if creada.PersonaID == nil || *creada.PersonaID != 42 {
		t.Errorf("esperaba PersonaID=42 en la visita creada, got %v", creada.PersonaID)
	}
}
