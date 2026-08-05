package visitas

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log"
	"net/http"
	"strconv"
	"strings"
	"time"

	"kigo-autonomia-backend/internal/platform/ctxkeys"

	"github.com/gin-gonic/gin"
)

// SseHub interfaz para evitar dependencia circular con el paquete sse
type SseHub interface {
	Broadcast(data []byte)
	Subscribe() chan []byte
	Unsubscribe(ch chan []byte)
}

type Handler struct {
	repo       *Repository
	uploadsDir string
	llmURL     string
	sseHub     SseHub
}

func NewHandler(repo *Repository, uploadsDir string, llmURL string, hub SseHub) *Handler {
	return &Handler{repo: repo, uploadsDir: uploadsDir, llmURL: llmURL, sseHub: hub}
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
// @Param titular formData string true "Nombre completo del visitante titular"
// @Param tipo_documento formData string true "INE, PASAPORTE o LICENCIA"
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

	cfg, err := h.repo.GetKioskoConfig(uint(kioskoID))
	if err != nil {
		c.JSON(
			http.StatusInternalServerError,
			gin.H{"error": "no se pudo obtener la configuracion del kiosko"},
		)
		return
	}

	if errMsg := validarCamposCondicionales(req, cfg); errMsg != "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": errMsg})
		return
	}

	var fotoDocumentoURL string
	if req.FotoDocumento != nil {
		fotoDocumentoURL, err = guardarFotoVisitante(c, req.FotoDocumento, h.uploadsDir)
		if err != nil {
			if errors.Is(err, errFormatoFotoInvalido) {
				c.JSON(http.StatusBadRequest, gin.H{"error": "foto_documento: " + err.Error()})
				return
			}
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
	}

	var fotoRostroURL string
	if req.FotoRostro != nil {
		fotoRostroURL, err = guardarFotoVisitante(c, req.FotoRostro, h.uploadsDir)
		if err != nil {
			if errors.Is(err, errFormatoFotoInvalido) {
				c.JSON(http.StatusBadRequest, gin.H{"error": "foto_rostro: " + err.Error()})
				return
			}
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
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
		Titular:          strings.ToUpper(strings.TrimSpace(req.Titular)),
		TipoVisitante:    req.TipoVisitante,
		TipoDocumento:    req.TipoDocumento,
		Curp:             strings.ToUpper(strings.TrimSpace(req.Curp)),
		FotoDocumentoURL: fotoDocumentoURL,
		FotoRostroURL:    fotoRostroURL,
		FotoPlacaURL:     fotoPlacaURL,
		MotivoVisita:     req.MotivoVisita,
		CasaDestino:      strings.ToUpper(strings.TrimSpace(req.CasaDestino)),
		Placa:            strings.ToUpper(strings.TrimSpace(req.Placa)),
		Estado:           EstadoPendiente,
		KioskoID:         uint(kioskoID),
	}

	if err := h.repo.Create(v); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, toVisitaResponse(*v))

	// Análisis asíncrono — no bloquea la respuesta al kiosko
	visitaCopy := *v
	go func() {
		ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
		defer cancel()

		cfg, err := h.repo.GetKioskoConfig(visitaCopy.KioskoID)
		if err != nil {
			return
		}

		historial, err := h.repo.HistorialPorCURP(visitaCopy.Curp)
		if err != nil {
			return
		}
		var historialPrevio []Visita
		for _, vh := range historial {
			if vh.ID != visitaCopy.ID {
				historialPrevio = append(historialPrevio, vh)
			}
		}

		sc := AnalizarVisita(historialPrevio, visitaCopy, cfg.UmbralConfianzaVisitas)
		resumen, _ := GenerarResumen(ctx, h.llmURL, sc)
		sc.ResumenTexto = resumen

		tieneAnomalias := sc.AnomaliaMatricula || sc.CambioModalidad || sc.HorarioInusual ||
			sc.RechazadoPrevio || sc.OCRSospechoso

		nuevoEstado := EstadoPendiente
		if sc.Confiable && !tieneAnomalias && cfg.AutoPassHabilitado {
			nuevoEstado = EstadoAprobado
		} else if tieneAnomalias || (sc.Confiable && !cfg.AutoPassHabilitado) {
			nuevoEstado = EstadoRevision
		}

		if nuevoEstado != EstadoPendiente {
			if err := h.repo.ActualizarEstadoConScore(visitaCopy.ID, nuevoEstado, false); err != nil {
				log.Printf("ActualizarEstadoConScore visita %d: %v", visitaCopy.ID, err)
			}
		}

		if h.sseHub != nil && (nuevoEstado == EstadoRevision || nuevoEstado == EstadoPendiente) {
			visitaCopy.Estado = nuevoEstado
			if jsonData, err := json.Marshal(toVisitaResponse(visitaCopy)); err == nil {
				h.sseHub.Broadcast(jsonData)
			}
		}
	}()
}

// aplicarExpiracionSiVencida mueve una visita PENDIENTE a REVISION cuando supera
// el tiempo de espera configurado para su kiosko (TiempoEsperaMin, 10 min si no
// hay config), para que nunca se quede colgada esperando una respuesta que no llega.
func (h *Handler) aplicarExpiracionSiVencida(v *Visita) {
	if v.Estado != EstadoPendiente {
		return
	}

	cfg, err := h.repo.GetKioskoConfig(v.KioskoID)
	if err != nil {
		return
	}

	tiempoEsperaMin := cfg.TiempoEsperaMin
	if tiempoEsperaMin <= 0 {
		tiempoEsperaMin = 10
	}

	limite := v.CreatedAt.Add(time.Duration(tiempoEsperaMin) * time.Minute)
	if time.Now().Before(limite) {
		return
	}

	if err := h.repo.UpdateEstado(v.ID, EstadoRevision); err != nil {
		return
	}
	v.Estado = EstadoRevision

	if h.sseHub != nil {
		if jsonData, err := json.Marshal(toVisitaResponse(*v)); err == nil {
			h.sseHub.Broadcast(jsonData)
		}
	}
}

// GetVisitaEstado devuelve el estado actual de una visita para el kiosko que la creo
//
// @Summary Consultar estado de visita (kiosko)
// @Description Usado por el kiosko para hacer polling del estado mientras espera aprobacion
// @Tags visitas
// @Produce json
// @Param id path int true "ID del kiosko"
// @Param visitaId path int true "ID de la visita"
// @Success 200 {object} VisitaResponse
// @Failure 404 {object} map[string]string
// @Router /kioskos/{id}/visitas/{visitaId} [get]
func (h *Handler) GetVisitaEstado(c *gin.Context) {
	kioskoIDStr := c.Param("id")
	kioskoID, err := strconv.ParseUint(kioskoIDStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID de kiosko invalido"})
		return
	}

	if !kioskoSesionAutorizada(c, uint(kioskoID)) {
		return
	}

	visitaID, err := strconv.ParseUint(c.Param("visitaId"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID de visita invalido"})
		return
	}

	v, err := h.repo.FindByIDAndKioskoID(uint(visitaID), uint(kioskoID))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "visita no encontrada"})
		return
	}

	h.aplicarExpiracionSiVencida(v)

	c.JSON(http.StatusOK, toVisitaResponse(*v))
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

	h.aplicarExpiracionSiVencida(v)

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
// @Param q query string false "Búsqueda parcial por titular, CURP o clave"
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
		if tipo != DocumentoINE && tipo != DocumentoPasaporte && tipo != DocumentoLicencia && tipo != DocumentoQR && tipo != DocumentoPIN {
			c.JSON(http.StatusBadRequest, gin.H{"error": "tipo_documento invalido"})
			return
		}
		filtros.TipoDocumento = &tipo
	}
	if estadoStr := c.Query("estado"); estadoStr != "" {
		estado := EstadoVisita(estadoStr)
		if estado != EstadoPendiente && estado != EstadoAprobado && estado != EstadoRechazado && estado != EstadoRevision {
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
	for i := range list {
		h.aplicarExpiracionSiVencida(&list[i])
		items = append(items, toVisitaListItemResponse(list[i]))
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

// StreamSolicitudes abre una conexión SSE y envía nuevas visitas al cliente
//
// @Summary Stream SSE de solicitudes
// @Tags visitas
// @Produce text/event-stream
// @Success 200
// @Router /kioskos/solicitudes/stream [get]
func (h *Handler) StreamSolicitudes(c *gin.Context) {
	c.Header("Content-Type", "text/event-stream")
	c.Header("Cache-Control", "no-cache")
	c.Header("Connection", "keep-alive")
	c.Header("X-Accel-Buffering", "no")

	ch := h.sseHub.Subscribe()
	defer h.sseHub.Unsubscribe(ch)

	c.Stream(func(w io.Writer) bool {
		select {
		case data, ok := <-ch:
			if !ok {
				return false
			}
			fmt.Fprintf(w, "data: %s\n\n", data)
			return true
		case <-c.Request.Context().Done():
			return false
		}
	})
}

// ListarReportes devuelve los ultimos 7 reportes de IA
//
// @Summary Listar reportes de IA
// @Tags visitas
// @Produce json
// @Success 200
// @Router /visitas/reportes [get]
func (h *Handler) ListarReportes(c *gin.Context) {
	repo := &reporteRepository{db: h.repo.db}
	reportes, err := repo.ultimos(7)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error obteniendo reportes"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"reportes": reportes})
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
