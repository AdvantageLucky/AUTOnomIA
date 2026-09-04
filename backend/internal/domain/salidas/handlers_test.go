package salidas

import (
	"context"
	"net/http"
	"net/http/httptest"
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
	if err := db.AutoMigrate(&Salida{}, &kiosko.Kiosko{}); err != nil {
		t.Fatalf("no se pudo migrar: %v", err)
	}
	db.Create(&kiosko.Kiosko{Model: gorm.Model{ID: 1}, TenantID: 1, Tipo: kiosko.KioskoPeatonal, Nombre: "Salida Principal", ClaveKiosko: "x", AdminID: 1})
	return db
}

func injectTestCtx(c *gin.Context, key string, val any) {
	c.Set(key, val)
	c.Request = c.Request.WithContext(context.WithValue(c.Request.Context(), key, val))
}

// TestReportarYListar_AparaceEnLaBitacora cubre el camino feliz: el kiosko
// de salida reporta un tap y el admin lo ve en la bitácora, con el nombre
// del kiosko resuelto vía join -- mismo patrón que seguridad.
func TestReportarYListar_AparaceEnLaBitacora(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db := setupTestDB(t)
	h := NewHandler(NewRepository(db), "/tmp")

	router := gin.New()
	router.POST("/kioskos/:id/salidas/", func(c *gin.Context) {
		injectTestCtx(c, ctxkeys.TenantID, uint(1))
		injectTestCtx(c, ctxkeys.KioskoID, uint(1))
		h.Reportar(c)
	})
	router.GET("/salidas/", func(c *gin.Context) {
		injectTestCtx(c, ctxkeys.TenantID, uint(1))
		h.Listar(c)
	})

	req := httptest.NewRequest(http.MethodPost, "/kioskos/1/salidas/", strings.NewReader(""))
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)
	if w.Code != http.StatusOK {
		t.Fatalf("esperaba 200, got %d: %s", w.Code, w.Body.String())
	}

	reqList := httptest.NewRequest(http.MethodGet, "/salidas/", nil)
	wList := httptest.NewRecorder()
	router.ServeHTTP(wList, reqList)
	if wList.Code != http.StatusOK {
		t.Fatalf("esperaba 200 en listado, got %d: %s", wList.Code, wList.Body.String())
	}
	bodyStr := wList.Body.String()
	if !strings.Contains(bodyStr, `"total":1`) {
		t.Errorf("esperaba total=1, got %s", bodyStr)
	}
	if !strings.Contains(bodyStr, `"kiosko_nombre":"Salida Principal"`) {
		t.Errorf("esperaba kiosko_nombre resuelto por join, got %s", bodyStr)
	}
}

// TestReportar_SesionNoCorrespondeAlKiosko confirma el mismo chequeo de
// seguridad que ya usa el paquete seguridad: la sesion del kiosko debe
// corresponder exactamente al ID del path.
func TestReportar_SesionNoCorrespondeAlKiosko(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db := setupTestDB(t)
	h := NewHandler(NewRepository(db), "/tmp")

	router := gin.New()
	router.POST("/kioskos/:id/salidas/", func(c *gin.Context) {
		injectTestCtx(c, ctxkeys.TenantID, uint(1))
		injectTestCtx(c, ctxkeys.KioskoID, uint(99))
		h.Reportar(c)
	})

	req := httptest.NewRequest(http.MethodPost, "/kioskos/1/salidas/", strings.NewReader(""))
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)
	if w.Code != http.StatusForbidden {
		t.Fatalf("esperaba 403, got %d: %s", w.Code, w.Body.String())
	}
}
