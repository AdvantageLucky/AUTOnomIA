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
	"kigo-autonomia-backend/internal/domain/residente"
	"kigo-autonomia-backend/internal/platform/ctxkeys"
)

// personaDePrueba es un stand-in local del modelo persona.Persona (mismo
// nombre de tabla, solo las columnas que BuscarPersonaPorIdentidad lee) --
// no se puede importar el paquete persona aquí: persona ya importa visitas,
// e importarlo de vuelta desde un _test.go de este mismo paquete es un
// import cycle (persona.Persona vive en un paquete que depende de este).
type personaDePrueba struct {
	gorm.Model
	Telefono        string `gorm:"uniqueIndex"`
	Nombre          string
	ApellidoPaterno string
	Curp            string
	Embedding       residente.FloatArray `gorm:"type:float[]"`
}

func (personaDePrueba) TableName() string { return "personas" }

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

// crearResidenteDePrueba da de alta una Persona con Membresia activa en el
// tenant 1 -- mismos datos de identidad (CURP, embedding) que un residente
// real capturaría en completarIdentidad (kigo-app), para probar que
// RegisterVisita lo reconoce si llega por el flujo de visitante.
func crearResidenteDePrueba(t *testing.T, db *gorm.DB, curp string, embedding []float64) uint {
	t.Helper()
	if err := db.AutoMigrate(&personaDePrueba{}, &residente.Membresia{}); err != nil {
		t.Fatalf("no se pudo migrar persona/membresia: %v", err)
	}
	p := &personaDePrueba{
		Telefono:        "555" + curp, // uniqueIndex: variar por caso de prueba
		Nombre:          "Ivan",
		ApellidoPaterno: "Ramses",
		Curp:            curp,
		Embedding:       residente.FloatArray(embedding),
	}
	if err := db.Create(p).Error; err != nil {
		t.Fatalf("no se pudo crear persona: %v", err)
	}
	m := &residente.Membresia{
		PersonaID:   p.ID,
		TenantID:    1,
		CasaDestino: "CASA 1",
		Pin:         "hash",
		Status:      residente.ResidenteStatusActivo,
	}
	if err := db.Create(m).Error; err != nil {
		t.Fatalf("no se pudo crear membresia: %v", err)
	}
	return p.ID
}

// TestRegisterVisita_ReconoceResidentePorCurp reproduce el bug reportado: un
// residente que ya tiene Persona+Membresia activas, al llegar por el flujo
// de visitante (INE + rostro, sin PIN/QR) con la misma CURP de su INE, debe
// quedar enlazado a su propia identidad y autopasado -- no tratado como un
// visitante nuevo cuyo score de confianza empieza en cero.
func TestRegisterVisita_ReconoceResidentePorCurp(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db := setupHandlerTestDB(t)
	personaID := crearResidenteDePrueba(t, db, "RAIJ800101HDFMNV01", nil)

	h := NewHandler(NewRepository(db), "/tmp", "", nil, nil)
	router := gin.New()
	router.POST("/kioskos/:id/visitas/", func(c *gin.Context) {
		injectTestCtx(c, ctxkeys.TenantID, uint(1))
		injectTestCtx(c, ctxkeys.KioskoID, uint(1))
		h.RegisterVisita(c)
	})

	fields := map[string]string{
		"titular":        "Ivan Ramses",
		"tipo_visitante": "VISITANTE",
		"casa_destino":   "Casa 1",
		"curp":           "RAIJ800101HDFMNV01",
	}
	contentType, body := multipartBody(fields)
	req := httptest.NewRequest(http.MethodPost, "/kioskos/1/visitas/", body)
	req.Header.Set("Content-Type", contentType)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)
	if w.Code != http.StatusCreated {
		t.Fatalf("esperaba 201, got %d: %s", w.Code, w.Body.String())
	}

	var v Visita
	if err := db.Where("tenant_id = 1").First(&v).Error; err != nil {
		t.Fatalf("no se encontró la visita creada: %v", err)
	}
	if v.PersonaID == nil || *v.PersonaID != personaID {
		t.Errorf("esperaba PersonaID=%d, got %v", personaID, v.PersonaID)
	}
	if v.Estado != EstadoAprobado {
		t.Errorf("esperaba EstadoAprobado (autopase por identidad), got %v", v.Estado)
	}
	if v.AutorizadoPorTipo != AutorizadorPropio {
		t.Errorf("esperaba AutorizadorPropio, got %q", v.AutorizadoPorTipo)
	}
}

// TestRegisterVisita_ReconoceResidentePorRostro cubre el mismo caso pero sin
// CURP (p.ej. INE ilegible u OCR fallido) -- solo con el embedding facial,
// que debe cruzar contra Persona.Embedding con el mismo umbral que usa el
// login de residente (kiosko_configs.umbral_similitud_cara).
func TestRegisterVisita_ReconoceResidentePorRostro(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db := setupHandlerTestDB(t)
	embeddingResidente := []float64{1, 0, 0}
	personaID := crearResidenteDePrueba(t, db, "", embeddingResidente)

	h := NewHandler(NewRepository(db), "/tmp", "", nil, nil)
	router := gin.New()
	router.POST("/kioskos/:id/visitas/", func(c *gin.Context) {
		injectTestCtx(c, ctxkeys.TenantID, uint(1))
		injectTestCtx(c, ctxkeys.KioskoID, uint(1))
		h.RegisterVisita(c)
	})

	fields := map[string]string{
		"titular":          "Ivan Ramses",
		"tipo_visitante":   "VISITANTE",
		"casa_destino":     "Casa 1",
		"embedding_rostro": "[1,0,0]", // idéntico al de la Persona -> similitud 1.0
	}
	contentType, body := multipartBody(fields)
	req := httptest.NewRequest(http.MethodPost, "/kioskos/1/visitas/", body)
	req.Header.Set("Content-Type", contentType)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)
	if w.Code != http.StatusCreated {
		t.Fatalf("esperaba 201, got %d: %s", w.Code, w.Body.String())
	}

	var v Visita
	if err := db.Where("tenant_id = 1").First(&v).Error; err != nil {
		t.Fatalf("no se encontró la visita creada: %v", err)
	}
	if v.PersonaID == nil || *v.PersonaID != personaID {
		t.Errorf("esperaba PersonaID=%d, got %v", personaID, v.PersonaID)
	}
	if v.Estado != EstadoAprobado {
		t.Errorf("esperaba EstadoAprobado (autopase por identidad), got %v", v.Estado)
	}
}

// TestRegisterVisita_VisitanteDesconocidoNoSeAutopasa evita una regresión
// obvia: un visitante que NO coincide con ningún residente activo debe
// seguir el flujo normal (EstadoPendiente), no autopasarse por accidente.
func TestRegisterVisita_VisitanteDesconocidoNoSeAutopasa(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db := setupHandlerTestDB(t)
	crearResidenteDePrueba(t, db, "OTRO900101HDFXYZ02", []float64{0, 1, 0})

	h := NewHandler(NewRepository(db), "/tmp", "", nil, nil)
	router := gin.New()
	router.POST("/kioskos/:id/visitas/", func(c *gin.Context) {
		injectTestCtx(c, ctxkeys.TenantID, uint(1))
		injectTestCtx(c, ctxkeys.KioskoID, uint(1))
		h.RegisterVisita(c)
	})

	fields := map[string]string{
		"titular":          "Visitante Desconocido",
		"tipo_visitante":   "VISITANTE",
		"casa_destino":     "Casa 1",
		"curp":             "AJAX900101HDFAAA03",
		"embedding_rostro": "[1,0,0]", // opuesto al [0,1,0] del residente -> similitud 0
	}
	contentType, body := multipartBody(fields)
	req := httptest.NewRequest(http.MethodPost, "/kioskos/1/visitas/", body)
	req.Header.Set("Content-Type", contentType)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)
	if w.Code != http.StatusCreated {
		t.Fatalf("esperaba 201, got %d: %s", w.Code, w.Body.String())
	}

	var v Visita
	if err := db.Where("tenant_id = 1").First(&v).Error; err != nil {
		t.Fatalf("no se encontró la visita creada: %v", err)
	}
	if v.PersonaID != nil {
		t.Errorf("no esperaba PersonaID, got %v", *v.PersonaID)
	}
	if v.Estado != EstadoPendiente {
		t.Errorf("esperaba EstadoPendiente, got %v", v.Estado)
	}
}
