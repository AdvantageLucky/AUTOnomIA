package visitas

import (
	"context"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"

	"kigo-autonomia-backend/internal/domain/kiosko"
	"kigo-autonomia-backend/internal/platform/ctxkeys"
)

func setupHandlerTestDB(t *testing.T) *gorm.DB {
	db := setupTestDB(t)
	if err := db.AutoMigrate(&kiosko.KioskoConfig{}, &kiosko.Kiosko{}); err != nil {
		t.Fatalf("no se pudo migrar kiosko: %v", err)
	}
	db.Create(&kiosko.Kiosko{Model: gorm.Model{ID: 1}, TenantID: 1, Tipo: kiosko.KioskoPeatonal, Nombre: "K1", ClaveKiosko: "x", AdminID: 1})
	db.Create(&kiosko.KioskoConfig{KioskoID: 1, TenantID: 1})
	// GORM trata un bool false explicito como "no seteado" cuando el campo
	// tiene default:true en su tag, y usa el default en el Create de arriba
	// — hay que forzarlo con un Update aparte para que la config de prueba
	// no exija foto_rostro (no es lo que este test verifica).
	db.Model(&kiosko.KioskoConfig{}).Where("kiosko_id = ?", 1).Update("foto_rostro_visitante", false)
	return db
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

// injectCtx replica el patron de auth.RequireKiosko: mete la identidad tanto
// en el store de gin.Context como en el context.Context real de la request,
// porque los scopes ByTenant leen db.Statement.Context (el segundo), no
// c.Get (el primero).
func injectTestCtx(c *gin.Context, key string, val any) {
	c.Set(key, val)
	c.Request = c.Request.WithContext(context.WithValue(c.Request.Context(), key, val))
}

func TestRegisterVisita_Idempotente(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db := setupHandlerTestDB(t)
	h := NewHandler(NewRepository(db), "/tmp", "", nil, nil)

	router := gin.New()
	router.POST("/kioskos/:id/visitas/", func(c *gin.Context) {
		injectTestCtx(c, ctxkeys.TenantID, uint(1))
		injectTestCtx(c, ctxkeys.KioskoID, uint(1))
		h.RegisterVisita(c)
	})

	fields := map[string]string{
		"titular":        "Visitante De Prueba",
		"tipo_visitante": "VISITANTE",
		"casa_destino":   "Casa 1",
		"client_id":      "mismo-uuid",
	}

	contentType, body := multipartBody(fields)
	req1 := httptest.NewRequest(http.MethodPost, "/kioskos/1/visitas/", body)
	req1.Header.Set("Content-Type", contentType)
	w1 := httptest.NewRecorder()
	router.ServeHTTP(w1, req1)
	if w1.Code != http.StatusCreated {
		t.Fatalf("primer POST: esperaba 201, got %d: %s", w1.Code, w1.Body.String())
	}

	contentType2, body2 := multipartBody(fields)
	req2 := httptest.NewRequest(http.MethodPost, "/kioskos/1/visitas/", body2)
	req2.Header.Set("Content-Type", contentType2)
	w2 := httptest.NewRecorder()
	router.ServeHTTP(w2, req2)
	if w2.Code != http.StatusCreated {
		t.Fatalf("segundo POST (mismo client_id): esperaba 201, got %d: %s", w2.Code, w2.Body.String())
	}

	var count int64
	db.Model(&Visita{}).Where("tenant_id = 1").Count(&count)
	if count != 1 {
		t.Errorf("esperaba 1 sola visita creada, hay %d", count)
	}
}
