package visitantes

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

	uploadsDir = "./web/uploads/visitantes"
)

// fotoContentTypesPermitidos solo acepta jpg/png: lo que manda el navegador/kiosko segun el
// archivo elegido, validado junto con la extension (ninguno de los dos es infalible solo, pero
// juntos son suficiente para un upload autenticado por sesion de kiosko, no publico)
var fotoContentTypesPermitidos = map[string]bool{
	"image/jpeg": true,
	"image/png":  true,
}

var fotoExtensionesPermitidas = map[string]bool{
	".jpg":  true,
	".jpeg": true,
	".png":  true,
}

// guardarFotoVisitante guarda en disco el archivo subido con un nombre generado por el servidor
// (nunca el nombre que manda el cliente, para no exponer la ruta en disco a control del cliente)
// y devuelve la URL publica desde la que se sirve (ver r.Static en internal/router/router.go)
func guardarFotoVisitante(c *gin.Context, foto *multipart.FileHeader) (string, error) {
	ext := strings.ToLower(filepath.Ext(foto.Filename))
	if !fotoExtensionesPermitidas[ext] ||
		!fotoContentTypesPermitidos[foto.Header.Get("Content-Type")] {
		return "", errFormatoFotoInvalido
	}

	nombreArchivo, err := generateNombreArchivo(ext)
	if err != nil {
		return "", err
	}

	if err := c.SaveUploadedFile(foto, filepath.Join(uploadsDir, nombreArchivo)); err != nil {
		return "", err
	}

	scheme := "http"
	if c.Request.TLS != nil {
		scheme = "https"
	}
	return fmt.Sprintf("%s://%s/uploads/visitantes/%s", scheme, c.Request.Host, nombreArchivo), nil
}

// generateNombreArchivo genera un nombre de archivo aleatorio de alta entropia para una foto subida
func generateNombreArchivo(ext string) (string, error) {
	b := make([]byte, 16)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	return hex.EncodeToString(b) + ext, nil
}

// parsePagination lee los query params page y page_size, con valores por defecto y limite maximo
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

// accesoSesionAutorizada verifica que la sesion de kiosko autenticada (acceso_id puesto en el
// contexto por auth.RequireAcceso) corresponde al Acceso de la URL. Sin esto, un kiosko logeado
// en el Acceso 3 podria registrar/leer visitantes del Acceso 5 solo cambiando el :id de la URL
func accesoSesionAutorizada(c *gin.Context, accesoID uint) bool {
	sesionAccesoID := c.MustGet(ctxkeys.AccesoID).(uint)
	if sesionAccesoID != accesoID {
		c.JSON(http.StatusForbidden, gin.H{"error": "la sesion no corresponde a este acceso"})
		return false
	}
	return true
}

// toVisitanteResponse mapea un Visitante a su DTO de respuesta completo (detalle, historial)
func toVisitanteResponse(v Visitante) VisitanteResponse {
	return VisitanteResponse{
		ID:               v.ID,
		Nombre:           v.Nombre,
		TipoDocumento:    v.TipoDocumento,
		ClaveLector:      v.ClaveLector,
		Curp:             v.Curp,
		FotoDocumentoURL: v.FotoDocumentoURL,
		FotoRostroURL:    v.FotoRostroURL,
		AccesoID:         v.AccesoID,
		CreatedAt:        v.CreatedAt,
	}
}

// toVisitanteListItemResponse mapea un Visitante a su DTO reducido de listado (sin CURP/ClaveLector)
func toVisitanteListItemResponse(v Visitante) VisitanteListItemResponse {
	return VisitanteListItemResponse{
		ID:            v.ID,
		Nombre:        v.Nombre,
		TipoDocumento: v.TipoDocumento,
		AccesoID:      v.AccesoID,
		CreatedAt:     v.CreatedAt,
	}
}

// RegisterVisitante crea un nuevo Visitante para el Acceso indicado en la URL. Va con
// multipart/form-data porque el kiosko sube dos fotos en la misma llamada: la del documento
// (INE/pasaporte/licencia) y la de la cara de la persona; el servidor las guarda en disco (ver
// guardarFotoVisitante) y genera las URLs, nunca las manda el cliente
// Request: id uint (URL Param, acceso_id) y VisitanteRequest (multipart/form-data)
// Response: VisitanteResponse
//
// @Summary Registrar visitante
// @Description Registra el ingreso de un nuevo visitante por un Acceso, subiendo la foto del documento y la de su rostro en la misma llamada
// @Tags visitantes
// @Accept multipart/form-data
// @Produce json
// @Param id path int true "ID del acceso"
// @Param nombre formData string true "Nombre del visitante"
// @Param tipo_documento formData string true "INE, PASAPORTE o LICENCIA"
// @Param clave_lector formData string true "Clave leida del documento"
// @Param curp formData string true "CURP (18 caracteres)"
// @Param foto_documento formData file true "Foto del documento (INE/pasaporte/licencia), jpg o png"
// @Param foto_rostro formData file true "Foto de la cara de la persona, jpg o png"
// @Success 201 {object} VisitanteResponse
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /accesos/{id}/visitantes [post]
func (h *Handler) RegisterVisitante(c *gin.Context) {
	accesoIDStr := c.Param("id")
	accesoID, err := strconv.ParseUint(accesoIDStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID de acceso invalido"})
		return
	}

	if !accesoSesionAutorizada(c, uint(accesoID)) {
		return
	}

	var req VisitanteRequest
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

	v := &Visitante{
		Nombre:           req.Nombre,
		TipoDocumento:    req.TipoDocumento,
		ClaveLector:      req.ClaveLector,
		Curp:             req.Curp,
		FotoDocumentoURL: fotoDocumentoURL,
		FotoRostroURL:    fotoRostroURL,
		AccesoID:         uint(accesoID),
	}

	if err := h.repo.Create(v); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, toVisitanteResponse(*v))
}

// GetVisitanteByIDAndAdminID busca un registro de visita especifico en cualquier Acceso del admin autenticado (dashboard)
// Request: id uint (URL Param)
// Response: VisitanteResponse
//
// @Summary Obtener un registro de visita (dashboard)
// @Description Busca un registro de visita especifico, sin importar a cual Acceso del admin pertenece
// @Tags visitantes
// @Produce json
// @Param id path int true "ID del registro de visita"
// @Success 200 {object} VisitanteResponse
// @Failure 400 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Router /visitantes/{id} [get]
func (h *Handler) GetVisitanteByIDAndAdminID(c *gin.Context) {
	adminID := c.MustGet(ctxkeys.AdminID).(uint)

	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID invalido"})
		return
	}

	v, err := h.repo.FindByIDAndAdminID(uint(id), adminID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "registro de visita no encontrado"})
		return
	}

	c.JSON(http.StatusOK, toVisitanteResponse(*v))
}

// ListarVisitantes lista, paginado, los Visitantes del admin autenticado (dashboard), combinando
// filtros opcionales: acceso_id (acota a un Acceso del admin, y de paso confirma que es suyo),
// tipo_documento (INE/PASAPORTE/LICENCIA exacto) y q (texto libre, busca parcial en nombre, curp y
// clave_lector). Cada fila trae solo info no sensible: para ver CURP y clave de lector hay que
// entrar al detalle de una entrada especifica via GetVisitanteByIDAndAdminID
// Request: query params page, page_size, acceso_id, tipo_documento, q (todos opcionales)
// Response: VisitantesPaginadosResponse
//
// @Summary Listar visitantes del admin (dashboard)
// @Description Devuelve, paginados, los registros de visita del admin autenticado. Filtros opcionales combinables: acceso_id, tipo_documento, q (busqueda parcial en nombre/curp/clave_lector). No incluye CURP ni clave_lector en la respuesta (ver GET /visitantes/{id} para el detalle completo)
// @Tags visitantes
// @Produce json
// @Param page query int false "Numero de pagina (default 1)"
// @Param page_size query int false "Tamaño de pagina (default 20, max 100)"
// @Param acceso_id query int false "Acota el listado a un Acceso especifico del admin"
// @Param tipo_documento query string false "INE, PASAPORTE o LICENCIA"
// @Param q query string false "Busqueda parcial por nombre, CURP o clave de lector"
// @Success 200 {object} VisitantesPaginadosResponse
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /visitantes [get]
func (h *Handler) ListarVisitantes(c *gin.Context) {
	adminID := c.MustGet(ctxkeys.AdminID).(uint)
	page, pageSize := parsePagination(c)

	var filtros VisitanteFiltros
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
	filtros.Q = strings.TrimSpace(c.Query("q"))

	visitantesList, total, err := h.repo.FindAllByAdminID(adminID, filtros, page, pageSize)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	visitantesRes := make([]VisitanteListItemResponse, 0, len(visitantesList))
	for _, v := range visitantesList {
		visitantesRes = append(visitantesRes, toVisitanteListItemResponse(v))
	}

	c.JSON(http.StatusOK, VisitantesPaginadosResponse{
		Visitantes: visitantesRes,
		Total:      total,
		Page:       page,
		PageSize:   pageSize,
	})
}

// HistorialVisitante busca todos los registros de visita de una persona por su CURP, con info completa
// Request: query param curp
// Response: HistorialVisitanteResponse
//
// @Summary Historial de visitas por CURP (dashboard)
// @Description Devuelve todos los registros de visita de una persona, identificada por su CURP, en cualquier Acceso del admin autenticado. Util para saber si ya vino antes y cuantas veces
// @Tags visitantes
// @Produce json
// @Param curp query string true "CURP de la persona"
// @Success 200 {object} HistorialVisitanteResponse
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /visitantes/buscar [get]
func (h *Handler) HistorialVisitante(c *gin.Context) {
	adminID := c.MustGet(ctxkeys.AdminID).(uint)

	curp := c.Query("curp")
	if curp == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "curp es requerido"})
		return
	}

	visitas, err := h.repo.FindByCurpAndAdminID(curp, adminID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	visitasRes := make([]VisitanteResponse, 0, len(visitas))
	for _, v := range visitas {
		visitasRes = append(visitasRes, toVisitanteResponse(v))
	}

	c.JSON(http.StatusOK, HistorialVisitanteResponse{
		Curp:         curp,
		TotalVisitas: len(visitasRes),
		Visitas:      visitasRes,
	})
}
