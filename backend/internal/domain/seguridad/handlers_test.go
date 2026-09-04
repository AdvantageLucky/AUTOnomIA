package seguridad

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"

	"github.com/gin-gonic/gin"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"

	"kigo-autonomia-backend/internal/domain/kiosko"
	"kigo-autonomia-backend/internal/platform/ctxkeys"
)

func setupTestDB(t *testing.T) *gorm.DB {
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	if err != nil {
		t.Fatalf("no se pudo abrir sqlite en memoria: %v", err)
	}
	sqlDB, _ := db.DB()
	sqlDB.SetMaxOpenConns(1)
	if err := db.AutoMigrate(&EventoSeguridad{}, &kiosko.Kiosko{}); err != nil {
		t.Fatalf("no se pudo migrar: %v", err)
	}
	db.Create(&kiosko.Kiosko{Model: gorm.Model{ID: 1}, TenantID: 1, Tipo: kiosko.KioskoPeatonal, Nombre: "K1", ClaveKiosko: "x", AdminID: 1})
	return db
}

func injectTestCtx(c *gin.Context, key string, val any) {
	c.Set(key, val)
	c.Request = c.Request.WithContext(context.WithValue(c.Request.Context(), key, val))
}

// TestReportar_TipoInvalido_Rechaza confirma la validación del tipo antes
// de guardar nada.
func TestReportar_TipoInvalido_Rechaza(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db := setupTestDB(t)
	h := NewHandler(NewRepository(db), "/tmp", nil, nil)

	router := gin.New()
	router.POST("/kioskos/:id/eventos-seguridad/", func(c *gin.Context) {
		injectTestCtx(c, ctxkeys.TenantID, uint(1))
		injectTestCtx(c, ctxkeys.KioskoID, uint(1))
		h.Reportar(c)
	})

	req := httptest.NewRequest(http.MethodPost, "/kioskos/1/eventos-seguridad/", strings.NewReader("tipo=algo_invalido"))
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	if w.Code != http.StatusBadRequest {
		t.Fatalf("esperaba 400, got %d: %s", w.Code, w.Body.String())
	}
}

// TestReportarYListar_PinIncorrecto_AparaceEnElListado cubre el camino
// feliz: el kiosko reporta un PIN incorrecto y el admin lo ve en el listado,
// con el nombre del kiosko resuelto vía join.
func TestReportarYListar_PinIncorrecto_AparaceEnElListado(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db := setupTestDB(t)
	repo := NewRepository(db)
	h := NewHandler(repo, "/tmp", nil, nil)

	router := gin.New()
	router.POST("/kioskos/:id/eventos-seguridad/", func(c *gin.Context) {
		injectTestCtx(c, ctxkeys.TenantID, uint(1))
		injectTestCtx(c, ctxkeys.KioskoID, uint(1))
		h.Reportar(c)
	})
	router.GET("/eventos-seguridad/", func(c *gin.Context) {
		injectTestCtx(c, ctxkeys.TenantID, uint(1))
		h.Listar(c)
	})

	body := strings.NewReader("tipo=" + TipoPinIncorrecto + "&detalle=Casa+1")
	req := httptest.NewRequest(http.MethodPost, "/kioskos/1/eventos-seguridad/", body)
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)
	if w.Code != http.StatusOK {
		t.Fatalf("esperaba 200, got %d: %s", w.Code, w.Body.String())
	}

	reqList := httptest.NewRequest(http.MethodGet, "/eventos-seguridad/", nil)
	wList := httptest.NewRecorder()
	router.ServeHTTP(wList, reqList)
	if wList.Code != http.StatusOK {
		t.Fatalf("esperaba 200 en listado, got %d: %s", wList.Code, wList.Body.String())
	}
	bodyStr := wList.Body.String()
	if !strings.Contains(bodyStr, `"total":1`) {
		t.Errorf("esperaba total=1, got %s", bodyStr)
	}
	if !strings.Contains(bodyStr, `"kiosko_nombre":"K1"`) {
		t.Errorf("esperaba kiosko_nombre=K1 (join), got %s", bodyStr)
	}
	if !strings.Contains(bodyStr, `"detalle":"Casa 1"`) {
		t.Errorf("esperaba detalle='Casa 1', got %s", bodyStr)
	}
}

// TestReportarYListar_RostroNoReconocido_AparaceEnElListado cubre el tercer
// tipo de evento (reconocimiento facial de residente fallido) -- antes solo
// pin_incorrecto y qr_invalido pasaban la validación del handler.
func TestReportarYListar_RostroNoReconocido_AparaceEnElListado(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db := setupTestDB(t)
	h := NewHandler(NewRepository(db), "/tmp", nil, nil)

	router := gin.New()
	router.POST("/kioskos/:id/eventos-seguridad/", func(c *gin.Context) {
		injectTestCtx(c, ctxkeys.TenantID, uint(1))
		injectTestCtx(c, ctxkeys.KioskoID, uint(1))
		h.Reportar(c)
	})
	router.GET("/eventos-seguridad/", func(c *gin.Context) {
		injectTestCtx(c, ctxkeys.TenantID, uint(1))
		h.Listar(c)
	})

	body := strings.NewReader("tipo=" + TipoRostroNoReconocido)
	req := httptest.NewRequest(http.MethodPost, "/kioskos/1/eventos-seguridad/", body)
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)
	if w.Code != http.StatusOK {
		t.Fatalf("esperaba 200, got %d: %s", w.Code, w.Body.String())
	}

	reqList := httptest.NewRequest(http.MethodGet, "/eventos-seguridad/?tipo="+TipoRostroNoReconocido, nil)
	wList := httptest.NewRecorder()
	router.ServeHTTP(wList, reqList)
	bodyStr := wList.Body.String()
	if !strings.Contains(bodyStr, `"total":1`) {
		t.Errorf("esperaba total=1 filtrando por rostro_no_reconocido, got %s", bodyStr)
	}
}

// Caso reportado: se quiere poder correlacionar si el mismo rostro ya
// generó otro evento de seguridad antes (ej. la misma persona fallando el
// PIN varias veces, o probando PIN y luego un QR inválido). Dos embeddings
// casi idénticos deben contar como el mismo rostro; uno muy distinto no.
func TestReportar_CorrelacionaPorRostro(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db := setupTestDB(t)
	h := NewHandler(NewRepository(db), "/tmp", nil, nil)

	router := gin.New()
	router.POST("/kioskos/:id/eventos-seguridad/", func(c *gin.Context) {
		injectTestCtx(c, ctxkeys.TenantID, uint(1))
		injectTestCtx(c, ctxkeys.KioskoID, uint(1))
		h.Reportar(c)
	})

	embeddingA, _ := json.Marshal([]float64{1, 0, 0, 0})
	embeddingCasiIgual, _ := json.Marshal([]float64{0.99, 0.01, 0, 0})
	embeddingDistinto, _ := json.Marshal([]float64{0, 0, 0, 1})

	postEvento := func(embeddingJSON []byte) *httptest.ResponseRecorder {
		form := url.Values{}
		form.Set("tipo", TipoPinIncorrecto)
		form.Set("embedding_rostro", string(embeddingJSON))
		req := httptest.NewRequest(http.MethodPost, "/kioskos/1/eventos-seguridad/", strings.NewReader(form.Encode()))
		req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)
		return w
	}

	if w := postEvento(embeddingA); w.Code != http.StatusOK {
		t.Fatalf("primer evento: esperaba 200, got %d: %s", w.Code, w.Body.String())
	}

	var eventos []EventoSeguridad
	db.Find(&eventos)
	if len(eventos) != 1 || eventos[0].IntentosPrevios != 0 {
		t.Fatalf("primer evento no debería correlacionar con nada, got %+v", eventos)
	}

	if w := postEvento(embeddingCasiIgual); w.Code != http.StatusOK {
		t.Fatalf("segundo evento: esperaba 200, got %d: %s", w.Code, w.Body.String())
	}
	if w := postEvento(embeddingDistinto); w.Code != http.StatusOK {
		t.Fatalf("tercer evento: esperaba 200, got %d: %s", w.Code, w.Body.String())
	}

	eventos = nil
	db.Order("id").Find(&eventos)
	if len(eventos) != 3 {
		t.Fatalf("esperaba 3 eventos guardados, got %d", len(eventos))
	}
	if eventos[1].IntentosPrevios != 1 {
		t.Errorf("el rostro casi igual debía correlacionar con el primero (1 previo), got %d", eventos[1].IntentosPrevios)
	}
	if eventos[2].IntentosPrevios != 0 {
		t.Errorf("el rostro distinto no debía correlacionar con nada, got %d", eventos[2].IntentosPrevios)
	}
}
