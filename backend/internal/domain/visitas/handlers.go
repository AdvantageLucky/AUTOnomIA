/*
Package visitas

Handlers relacionados con el dominio visitas.
Hace uso del repository relacionado a visitas.

Hay dos grupos de endpoints con autenticacion distinta:

 1. Registro desde kiosko: POST /accesos/:id/visitas — autenticado con sesion de kiosko (RequireAcceso)
    Recibe multipart/form-data con datos del visitante y fotos (documento, rostro, placa opcional),

    guarda las fotos en disco via guardarFotoVisitante (ver storage.go) y crea la Visita en PENDIENTE

 2. Consulta y gestion del admin: GET/PATCH /visitas — autenticado con JWT de admin (RequireAdmin)
    listado paginado con filtros, detalle, historial por CURP y aprobacion/rechazo manual

Documentado con swag
*/
package visitas

import (
	"errors"
	"kigo-autonomia-backend/internal/platform/ctxkeys"
	"net/http"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"
)

type Handler struct {
	repo       *Repository
	uploadsDir string
}

func NewHandler(repo *Repository, uploadsDir string) *Handler {
	return &Handler{repo: repo, uploadsDir: uploadsDir}
}

func kioskoSesionAutorizada(c *gin.Context, kioskoID uint) bool {
	sesionKioskoID := c.MustGet(ctxkeys.KioskoID).(uint)
	if sesionKioskoID != kioskoID {
		c.JSON(http.StatusForbidden, gin.H{"error": "la sesion no corresponde a este kiosko"})
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
// @Param id path int true "ID del kiosko"
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
// @Router /kioskos/{id}/visitas [post]
func (h *Handler) RegisterVisita(c *gin.Context) {
	kioskoIDStr := c.Param("id")
	kioskoID, err := strconv.ParseUint(kioskoIDStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID de kiosko invalido"})
		return
	}

	if !kioskoSesionAutorizada(c, uint(kioskoID)) {
		return
	}

	var req VisitaRequest
	if err = c.ShouldBind(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	fotoDocumentoURL, err := guardarFotoVisitante(c, req.FotoDocumento, h.uploadsDir)
	if err != nil {
		if errors.Is(err, errFormatoFotoInvalido) {
			c.JSON(http.StatusBadRequest, gin.H{"error": "foto_documento: " + err.Error()})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	fotoRostroURL, err := guardarFotoVisitante(c, req.FotoRostro, h.uploadsDir)
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
		fotoPlacaURL, err = guardarFotoVisitante(c, req.FotoPlaca, h.uploadsDir)
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
		KioskoID: uint(kioskoID),
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
// @Param kiosko_id query int false "Filtrar por kiosko"
// @Param tipo_documento query string false "INE, PASAPORTE o LICENCIA"
// @Param estado query string false "PENDIENTE, APROBADO o RECHAZADO"
// @Param q query string false "Búsqueda parcial por nombre, CURP o clave"
// @Success 200 {object} VisitasPaginadasResponse
// @Router /visitas [get]
func (h *Handler) ListarVisitas(c *gin.Context) {
	adminID := c.MustGet(ctxkeys.AdminID).(uint)
	page, pageSize := parsePagination(c)

	var filtros VisitaFiltros
	if kioskoIDStr := c.Query("kiosko_id"); kioskoIDStr != "" {
		id, err := strconv.ParseUint(kioskoIDStr, 10, 32)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "kiosko_id invalido"})
			return
		}
		idUint := uint(id)
		filtros.KioskoID = &idUint
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
