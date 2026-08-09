package residente

import (
	"crypto/rand"
	"encoding/hex"
	"errors"
	"fmt"
	"log"
	"mime/multipart"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"

	"kigo-autonomia-backend/internal/domain/auth"
	"kigo-autonomia-backend/internal/domain/visitas"
	"kigo-autonomia-backend/internal/platform/ctxkeys"

	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

// destinoFinder permite al handler de residente resolver el destino_id
// sin importar directamente el package destinos (evita acoplamiento).
type destinoFinder interface {
	FindByNombreAndTenantID(nombre string, tenantID uint) (uint, error)
	ListNombresByTenantID(tenantID uint) ([]string, error)
}

type Handler struct {
	repo        *Repository
	destinoRepo destinoFinder
	jwtSecret   string
	db          *gorm.DB
	uploadsDir  string
}

func NewHandler(repo *Repository, destinoRepo destinoFinder, jwtSecret string, db *gorm.DB, uploadsDir string) *Handler {
	return &Handler{repo: repo, destinoRepo: destinoRepo, jwtSecret: jwtSecret, db: db, uploadsDir: uploadsDir}
}

func (h *Handler) LoginResidente(c *gin.Context) {
	var req LoginResidenteRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "campos incorrectos"})
		return
	}

	repoCtx := h.repo.WithContext(c.Request.Context())

	res, err := repoCtx.FindByCasaAndKiosko(req.CasaDestino, req.KioskoID)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "residente no encontrado"})
		return
	}

	if err := bcrypt.CompareHashAndPassword([]byte(res.Pin), []byte(req.Pin)); err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "pin incorrecto"})
		return
	}

	token, err := auth.GenerateResidenteToken(res.ID, res.TenantID, h.jwtSecret)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, auth.JWTResponse{AccessToken: token})
}

func (h *Handler) GetMe(c *gin.Context) {
	residenteID := c.MustGet(ctxkeys.ResidenteID).(uint)

	repoCtx := h.repo.WithContext(c.Request.Context())

	res, err := repoCtx.FindByID(residenteID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "residente no encontrado"})
		return
	}

	var destinoID *uint
	if h.destinoRepo != nil && res.CasaDestino != "" {
		tenantID, _ := c.Get(ctxkeys.TenantID)
		if tid, ok := tenantID.(uint); ok && tid > 0 {
			if id, err := h.destinoRepo.FindByNombreAndTenantID(res.CasaDestino, tid); err == nil {
				destinoID = &id
			}
		}
	}

	c.JSON(http.StatusOK, toResidenteResponse(*res, destinoID))
}

func (h *Handler) CrearResidente(c *gin.Context) {
	adminID := c.MustGet(ctxkeys.AdminID).(uint)
	tenantID := c.MustGet(ctxkeys.TenantID).(uint)

	var req CrearResidenteRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	repoCtx := h.repo.WithContext(c.Request.Context())

	if err := repoCtx.VerificarOwnershipKiosko(req.KioskoID, adminID); err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "kiosko no encontrado"})
		return
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(req.Pin), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	kioskoID := req.KioskoID
	res := &Residente{
		TenantID:        tenantID,
		Nombre:          req.Nombre,
		ApellidoPaterno: req.ApellidoPaterno,
		ApellidoMaterno: req.ApellidoMaterno,
		Pin:             string(hash),
		CasaDestino:     req.CasaDestino,
		Telefono:        req.Telefono,
		KioskoID:        &kioskoID,
		Status:          ResidenteStatusActivo,
	}

	if err := repoCtx.Create(res); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, toResidenteResponse(*res, nil))
}

// LoginResidentePublico loguea a un residente usando el código de instalación, su casa
// y PIN — no requiere conocer el kiosko_id. Endpoint público.
func (h *Handler) LoginResidentePublico(c *gin.Context) {
	codigo := c.Param("codigo")

	var req struct {
		CasaDestino string `json:"casa_destino" binding:"required"`
		Pin         string `json:"pin"          binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "casa_destino y pin son requeridos"})
		return
	}

	tenantID, _, _, err := h.repo.BuscarCentroPorCodigo(codigo)
	if err != nil || tenantID == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "centro no encontrado"})
		return
	}

	res, err := h.repo.FindPorPinPublico(tenantID, req.CasaDestino, req.Pin)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "credenciales incorrectas"})
		return
	}
	if res.Status != ResidenteStatusActivo {
		c.JSON(http.StatusForbidden, gin.H{"error": "tu solicitud aún no ha sido aprobada por el administrador"})
		return
	}

	token, err := auth.GenerateResidenteToken(res.ID, res.TenantID, h.jwtSecret)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, auth.JWTResponse{AccessToken: token})
}

// BuscarCentro devuelve la info básica del centro con el código dado. Endpoint público.
func (h *Handler) BuscarCentro(c *gin.Context) {
	codigo := c.Query("codigo")
	if codigo == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "parametro 'codigo' requerido"})
		return
	}

	id, nombre, direccion, err := h.repo.BuscarCentroPorCodigo(codigo)
	if err != nil || id == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "centro no encontrado"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"id":        id,
		"nombre":    nombre,
		"direccion": direccion,
		"codigo":    codigo,
	})
}

// ListarDestinosPublico devuelve los nombres de los destinos registrados en el centro,
// para que el residente busque y seleccione su casa al auto-registrarse. Endpoint público.
func (h *Handler) ListarDestinosPublico(c *gin.Context) {
	codigo := c.Param("codigo")

	tenantID, _, _, err := h.repo.BuscarCentroPorCodigo(codigo)
	if err != nil || tenantID == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "centro no encontrado"})
		return
	}

	nombres, err := h.destinoRepo.ListNombresByTenantID(tenantID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error listando destinos"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"destinos": nombres})
}

// AutoRegistrar crea un residente en estado pendiente. Endpoint público (sin auth).
func (h *Handler) AutoRegistrar(c *gin.Context) {
	codigo := c.Param("codigo")

	tenantID, nombre, _, err := h.repo.BuscarCentroPorCodigo(codigo)
	if err != nil || tenantID == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "centro no encontrado"})
		return
	}
	_ = nombre

	nombreR := strings.TrimSpace(c.PostForm("nombre"))
	apellidoP := strings.TrimSpace(c.PostForm("apellido_paterno"))
	apellidoM := strings.TrimSpace(c.PostForm("apellido_materno"))
	telefono := strings.TrimSpace(c.PostForm("telefono"))
	casaDestino := strings.TrimSpace(c.PostForm("casa_destino"))
	pin := strings.TrimSpace(c.PostForm("pin"))

	if nombreR == "" || apellidoP == "" || casaDestino == "" || pin == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "nombre, apellido_paterno, casa_destino y pin son requeridos"})
		return
	}
	if len(pin) < 4 || len(pin) > 6 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "el pin debe tener entre 4 y 6 dígitos"})
		return
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(pin), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error procesando pin"})
		return
	}

	var fotoCaraUrl string
	if fotoHeader, err := c.FormFile("foto_cara"); err == nil {
		url, err := h.guardarFotoCara(c, fotoHeader)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}
		fotoCaraUrl = url
	}

	res := &Residente{
		TenantID:        tenantID,
		Nombre:          nombreR,
		ApellidoPaterno: apellidoP,
		ApellidoMaterno: apellidoM,
		Telefono:        telefono,
		CasaDestino:     casaDestino,
		Pin:             string(hash),
		Status:          ResidenteStatusPendiente,
		FotoCaraUrl:     fotoCaraUrl,
	}

	if err := h.repo.Create(res); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"id":      res.ID,
		"status":  res.Status,
		"message": "Solicitud recibida. El administrador la revisará pronto.",
	})
}

// ConsultarEstado permite al residente verificar si su solicitud fue aprobada. Endpoint público.
func (h *Handler) ConsultarEstado(c *gin.Context) {
	codigo := c.Param("codigo")
	casaDestino := c.Query("casa_destino")
	pin := c.Query("pin")

	if casaDestino == "" || pin == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "casa_destino y pin requeridos"})
		return
	}

	tenantID, _, _, err := h.repo.BuscarCentroPorCodigo(codigo)
	if err != nil || tenantID == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "centro no encontrado"})
		return
	}

	res, err := h.repo.FindPorPinPublico(tenantID, casaDestino, pin)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "credenciales incorrectas"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": res.Status})
}

// ListarPendientes devuelve los residentes en estado pendiente del tenant del admin.
func (h *Handler) ListarPendientes(c *gin.Context) {
	tenantID := c.MustGet(ctxkeys.TenantID).(uint)

	list, err := h.repo.FindPendientesPorTenant(tenantID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	items := make([]ResidenteResponse, 0, len(list))
	for _, r := range list {
		items = append(items, toResidenteResponse(r, nil))
	}

	c.JSON(http.StatusOK, items)
}

// AprobarResidente cambia el status del residente a activo.
func (h *Handler) AprobarResidente(c *gin.Context) {
	tenantID := c.MustGet(ctxkeys.TenantID).(uint)

	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID inválido"})
		return
	}

	res, err := h.repo.FindByTenantAndID(tenantID, uint(id))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "residente no encontrado"})
		return
	}
	if res.Status != ResidenteStatusPendiente {
		c.JSON(http.StatusConflict, gin.H{"error": "el residente no está pendiente"})
		return
	}

	if err := h.repo.UpdateStatus(uint(id), ResidenteStatusActivo); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "residente aprobado"})
}

// RechazarResidente cambia el status del residente a rechazado.
func (h *Handler) RechazarResidente(c *gin.Context) {
	tenantID := c.MustGet(ctxkeys.TenantID).(uint)

	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID inválido"})
		return
	}

	res, err := h.repo.FindByTenantAndID(tenantID, uint(id))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "residente no encontrado"})
		return
	}
	if res.Status == ResidenteStatusRechazado {
		c.JSON(http.StatusConflict, gin.H{"error": "el residente ya fue rechazado"})
		return
	}

	if err := h.repo.UpdateStatus(uint(id), ResidenteStatusRechazado); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "residente rechazado"})
}

func (h *Handler) LoginResidenteDesdeKiosko(c *gin.Context) {
	kioskoIDStr := c.Param("id")
	kioskoID, err := strconv.ParseUint(kioskoIDStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID de kiosko invalido"})
		return
	}

	sesionKioskoID := c.MustGet(ctxkeys.KioskoID).(uint)
	if sesionKioskoID != uint(kioskoID) {
		c.JSON(http.StatusForbidden, gin.H{"error": "sesion no corresponde a este kiosko"})
		return
	}

	tenantID := c.MustGet(ctxkeys.TenantID).(uint)

	var req struct {
		Pin string `json:"pin" binding:"required,min=4,max=6"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	res, err := h.repo.FindPorPin(tenantID, req.Pin)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "PIN incorrecto"})
		return
	}

	v := &visitas.Visita{
		TenantID:      res.TenantID,
		Titular:       res.Nombre + " " + res.ApellidoPaterno,
		TipoVisitante: visitas.TipoResidente,
		TipoDocumento: visitas.DocumentoPIN,
		MotivoVisita:  "Acceso por PIN",
		CasaDestino:   res.CasaDestino,
		Estado:        visitas.EstadoAprobado,
		KioskoID:      uint(kioskoID),
	}

	if err := h.db.WithContext(c.Request.Context()).Create(v).Error; err != nil {
		log.Printf("LoginResidenteDesdeKiosko: error registrando visita: %v", err)
	}

	c.JSON(http.StatusOK, gin.H{
		"nombre":       res.Nombre + " " + res.ApellidoPaterno,
		"casa_destino": res.CasaDestino,
	})
}

func (h *Handler) ListarResidentesPorAcceso(c *gin.Context) {
	adminID := c.MustGet(ctxkeys.AdminID).(uint)

	kioskoIDStr := c.Param("id")
	kioskoID, err := strconv.ParseUint(kioskoIDStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID invalido"})
		return
	}

	repoCtx := h.repo.WithContext(c.Request.Context())

	if err := repoCtx.VerificarOwnershipKiosko(uint(kioskoID), adminID); err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "kiosko no encontrado"})
		return
	}

	list, err := repoCtx.FindByKioskoID(uint(kioskoID))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	items := make([]ResidenteResponse, 0, len(list))
	for _, r := range list {
		items = append(items, toResidenteResponse(r, nil))
	}

	c.JSON(http.StatusOK, items)
}

func (h *Handler) ListarResidentesAdmin(c *gin.Context) {
	adminID := c.MustGet(ctxkeys.AdminID).(uint)

	repoCtx := h.repo.WithContext(c.Request.Context())

	list, err := repoCtx.FindAllByAdminID(adminID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	items := make([]ResidenteResponse, 0, len(list))
	for _, r := range list {
		items = append(items, toResidenteResponse(r, nil))
	}

	c.JSON(http.StatusOK, items)
}

// guardarFotoCara guarda la foto de cara del residente en uploads/caras/.
func (h *Handler) guardarFotoCara(c *gin.Context, foto *multipart.FileHeader) (string, error) {
	ext := strings.ToLower(filepath.Ext(foto.Filename))
	permitidas := map[string]bool{".jpg": true, ".jpeg": true, ".png": true}
	permitidosCT := map[string]bool{"image/jpeg": true, "image/png": true}
	if !permitidas[ext] || !permitidosCT[foto.Header.Get("Content-Type")] {
		return "", errors.New("formato de foto no soportado (usa jpg o png)")
	}

	carasDir := filepath.Join(h.uploadsDir, "caras")
	if err := os.MkdirAll(carasDir, 0755); err != nil {
		return "", err
	}

	b := make([]byte, 16)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	nombreArchivo := hex.EncodeToString(b) + ext

	if err := c.SaveUploadedFile(foto, filepath.Join(carasDir, nombreArchivo)); err != nil {
		return "", err
	}

	scheme := "http"
	if c.Request.TLS != nil {
		scheme = "https"
	}
	return fmt.Sprintf("%s://%s/uploads/caras/%s", scheme, c.Request.Host, nombreArchivo), nil
}
