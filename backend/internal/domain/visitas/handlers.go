package visitas

import (
	"crypto/rand"
	"encoding/hex"
	"errors"
	"fmt"
	"mime/multipart"
	"net/http"
	"path/filepath"
	"strconv"
	"strings"

	"kigo-autonomia-backend/internal/platform/ctxkeys"

	"github.com/gin-gonic/gin"
)

var errFormatoFotoInvalido = errors.New("formato de foto no soportado (usa jpg o png)")

type Handler struct {
	repo *Repository
}

func NewHandler(repo *Repository) *Handler {
	return &Handler{repo: repo}
}

const (
	defaultPageSize = 20
	maxPageSize     = 100
	uploadsDir      = "./web/uploads/visitantes"
)

var fotoContentTypesPermitidos = map[string]bool{
	"image/jpeg": true,
	"image/png":  true,
}

var fotoExtensionesPermitidas = map[string]bool{
	".jpg":  true,
	".jpeg": true,
	".png":  true,
}

func guardarFotoVisitante(c *gin.Context, foto *multipart.FileHeader) (string, error) {
	ext := strings.ToLower(filepath.Ext(foto.Filename))
	if !fotoExtensionesPermitidas[ext] ||
		!fotoContentTypesPermitidos[foto.Header.Get("Content-Type")] {
		return "", errFormatoFotoInvalido
	}

	b := make([]byte, 16)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	nombreArchivo := hex.EncodeToString(b) + ext

	if err := c.SaveUploadedFile(foto, filepath.Join(uploadsDir, nombreArchivo)); err != nil {
		return "", err
	}

	scheme := "http"
	if c.Request.TLS != nil {
		scheme = "https"
	}
	return fmt.Sprintf("%s://%s/uploads/visitantes/%s", scheme, c.Request.Host, nombreArchivo), nil
}

func parsePagination(c *gin.Context) (page, pageSize int) {
	page, err := strconv.Atoi(c.Query("page"))
	if err != nil || page < 1 {
		page = 1
	}
	pageSize, err = strconv.Atoi(c.Query("page_size"))
	if err != nil || pageSize < 1 {
		pageSize = defaultPageSize
	}
	if pageSize > maxPageSize {
		pageSize = maxPageSize
	}
	return page, pageSize
}

func accesoSesionAutorizada(c *gin.Context, accesoID uint) bool {
	sesionAccesoID := c.MustGet(ctxkeys.AccesoID).(uint)
	if sesionAccesoID != accesoID {
		c.JSON(http.StatusForbidden, gin.H{"error": "la sesion no corresponde a este acceso"})
		return false
	}
	return true
}

// RegisterVisita registra una nueva visita desde el kiosko
//
// @Summary Registrar visita (kiosko)
// @Description Registra a un visitante y crea una solicitud de acceso en estado PENDIENTE
// @Tags visitas
// @Accept multipart/form-data
// @Produce json
// @Param id path int true "ID del acceso"
// @Param nombre formData string true "Nombre completo del visitante"
// @Param tipo_documento formData string true "INE, PASAPORTE o LICENCIA"
// @Param clave_lector formData string true "Clave leida del documento"
// @Param curp formData string true "CURP (18 caracteres)"
// @Param motivo_visita formData string true "Motivo de la visita"
// @Param casa_destino formData string true "Casa o departamento que visita"
// @Param placa formData string false "Placa del vehículo (opcional)"
// @Param foto_documento formData file true "Foto del documento, jpg o png"
// @Param foto_rostro formData file true "Foto del rostro, jpg o png"
// @Success 201 {object} VisitaResponse
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /accesos/{id}/visitas [post]
func (h *Handler) RegisterVisita(c *gin.Context) {
	accesoIDStr := c.Param("id")
	accesoID, err := strconv.ParseUint(accesoIDStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID de acceso invalido"})
		return
	}

	if !accesoSesionAutorizada(c, uint(accesoID)) {
		return
	}

	var req VisitaRequest
	if err := c.ShouldBind(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	fotoDocumentoURL, err := guardarFotoVisitante(c, req.FotoDocumento)
	if err != nil {
		if errors.Is(err, errFormatoFotoInvalido) {
			c.JSON(http.StatusBadRequest, gin.H{"error": "foto_documento: " + err.Error()})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	fotoRostroURL, err := guardarFotoVisitante(c, req.FotoRostro)
	if err != nil {
		if errors.Is(err, errFormatoFotoInvalido) {
			c.JSON(http.StatusBadRequest, gin.H{"error": "foto_rostro: " + err.Error()})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	var fotoPlacaURL string
	if req.FotoPlaca != nil {
		fotoPlacaURL, err = guardarFotoVisitante(c, req.FotoPlaca)
		if err != nil {
			if errors.Is(err, errFormatoFotoInvalido) {
				c.JSON(http.StatusBadRequest, gin.H{"error": "foto_placa: " + err.Error()})
				return
			}
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
	}

	v := &Visita{
		Nombre:           strings.ToUpper(strings.TrimSpace(req.Nombre)),
		TipoDocumento:    req.TipoDocumento,
		ClaveLector:      strings.ToUpper(strings.TrimSpace(req.ClaveLector)),
		Curp:             strings.ToUpper(strings.TrimSpace(req.Curp)),
		FotoDocumentoURL: fotoDocumentoURL,
		FotoRostroURL:    fotoRostroURL,
		FotoPlacaURL:     fotoPlacaURL,
		MotivoVisita:     req.MotivoVisita,
		CasaDestino:      strings.ToUpper(strings.TrimSpace(req.CasaDestino)),
		Placa:            strings.ToUpper(strings.TrimSpace(req.Placa)),
		Estado:           EstadoPendiente,
		AccesoID:         uint(accesoID),
	}

	if err := h.repo.Create(v); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, toVisitaResponse(*v))
}

// GetVisitaByID obtiene el detalle de una visita (dashboard admin)
//
// @Summary Obtener visita (dashboard)
// @Tags visitas
// @Produce json
// @Param id path int true "ID de la visita"
// @Success 200 {object} VisitaResponse
// @Failure 404 {object} map[string]string
// @Router /visitas/{id} [get]
func (h *Handler) GetVisitaByID(c *gin.Context) {
	adminID := c.MustGet(ctxkeys.AdminID).(uint)

	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID invalido"})
		return
	}

	v, err := h.repo.FindByIDAndAdminID(uint(id), adminID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "visita no encontrada"})
		return
	}

	c.JSON(http.StatusOK, toVisitaResponse(*v))
}

// ListarVisitas lista paginado las visitas del admin (dashboard)
//
// @Summary Listar visitas del admin (dashboard)
// @Tags visitas
// @Produce json
// @Param page query int false "Página (default 1)"
// @Param page_size query int false "Tamaño (default 20, max 100)"
// @Param acceso_id query int false "Filtrar por acceso"
// @Param tipo_documento query string false "INE, PASAPORTE o LICENCIA"
// @Param estado query string false "PENDIENTE, APROBADO o RECHAZADO"
// @Param q query string false "Búsqueda parcial por nombre, CURP o clave"
// @Success 200 {object} VisitasPaginadasResponse
// @Router /visitas [get]
func (h *Handler) ListarVisitas(c *gin.Context) {
	adminID := c.MustGet(ctxkeys.AdminID).(uint)
	page, pageSize := parsePagination(c)

	var filtros VisitaFiltros
	if accesoIDStr := c.Query("acceso_id"); accesoIDStr != "" {
		id, err := strconv.ParseUint(accesoIDStr, 10, 32)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "acceso_id invalido"})
			return
		}
		idUint := uint(id)
		filtros.AccesoID = &idUint
	}
	if tipoStr := c.Query("tipo_documento"); tipoStr != "" {
		tipo := TipoDocumento(tipoStr)
		if tipo != DocumentoINE && tipo != DocumentoPasaporte && tipo != DocumentoLicencia {
			c.JSON(http.StatusBadRequest, gin.H{"error": "tipo_documento invalido"})
			return
		}
		filtros.TipoDocumento = &tipo
	}
	if estadoStr := c.Query("estado"); estadoStr != "" {
		estado := EstadoVisita(estadoStr)
		if estado != EstadoPendiente && estado != EstadoAprobado && estado != EstadoRechazado {
			c.JSON(http.StatusBadRequest, gin.H{"error": "estado invalido"})
			return
		}
		filtros.Estado = &estado
	}
	filtros.Q = strings.TrimSpace(c.Query("q"))

	list, total, err := h.repo.FindAllByAdminID(adminID, filtros, page, pageSize)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	items := make([]VisitaListItemResponse, 0, len(list))
	for _, v := range list {
		items = append(items, toVisitaListItemResponse(v))
	}

	c.JSON(http.StatusOK, VisitasPaginadasResponse{
		Visitas:  items,
		Total:    total,
		Page:     page,
		PageSize: pageSize,
	})
}

// ActualizarEstado cambia el estado de una visita (aprobacion/rechazo manual desde el dashboard)
func (h *Handler) ActualizarEstado(c *gin.Context) {
	adminID := c.MustGet(ctxkeys.AdminID).(uint)

	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID invalido"})
		return
	}

	if _, err := h.repo.FindByIDAndAdminID(uint(id), adminID); err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "visita no encontrada"})
		return
	}

	var body struct {
		Estado string `json:"estado" binding:"required"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	estado := EstadoVisita(body.Estado)
	if estado != EstadoAprobado && estado != EstadoRechazado {
		c.JSON(http.StatusBadRequest, gin.H{"error": "estado debe ser APROBADO o RECHAZADO"})
		return
	}

	if err := h.repo.UpdateEstado(uint(id), estado); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"estado": string(estado)})
}

// HistorialVisita historial de visitas por CURP (dashboard)
//
// @Summary Historial de visitas por CURP
// @Tags visitas
// @Produce json
// @Param curp query string true "CURP"
// @Success 200 {object} HistorialVisitaResponse
// @Router /visitas/buscar [get]
func (h *Handler) HistorialVisita(c *gin.Context) {
	adminID := c.MustGet(ctxkeys.AdminID).(uint)

	curp := c.Query("curp")
	if curp == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "curp es requerido"})
		return
	}

	list, err := h.repo.FindByCurpAndAdminID(curp, adminID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	items := make([]VisitaResponse, 0, len(list))
	for _, v := range list {
		items = append(items, toVisitaResponse(v))
	}

	c.JSON(http.StatusOK, HistorialVisitaResponse{
		Curp:         curp,
		TotalVisitas: len(items),
		Visitas:      items,
	})
}
