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

func (h *Handler) RegisterVisita(c *gin.Context) {
	tenantID := c.MustGet(ctxkeys.TenantID).(uint)

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

	repoCtx := h.repo.WithContext(c.Request.Context())

	cfg, err := repoCtx.GetKioskoConfig(uint(kioskoID))
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
		TenantID:         tenantID,
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

	if err := repoCtx.Create(v); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, toVisitaResponse(*v))

	// Análisis asíncrono
	visitaCopy := *v
	go func() {
		ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
		defer cancel()

		// Propagamos el tenantID al contexto de la goroutine para que las consultas tengan acceso a la misma data
		asyncCtx := context.WithValue(ctx, ctxkeys.TenantID, tenantID)
		asyncRepo := h.repo.WithContext(asyncCtx)

		cfg, err := asyncRepo.GetKioskoConfig(visitaCopy.KioskoID)
		if err != nil {
			return
		}

		historial, err := asyncRepo.HistorialPorCURP(visitaCopy.Curp)
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
			if err := asyncRepo.ActualizarEstadoConScore(visitaCopy.ID, nuevoEstado, false); err != nil {
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

// aplicarExpiracionSiVencida requiere un repoCtx configurado para operar.
func (h *Handler) aplicarExpiracionSiVencida(repoCtx *Repository, v *Visita) {
	if v.Estado != EstadoPendiente {
		return
	}

	cfg, err := repoCtx.GetKioskoConfig(v.KioskoID)
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

	if err := repoCtx.UpdateEstado(v.ID, EstadoRevision); err != nil {
		return
	}
	v.Estado = EstadoRevision

	if h.sseHub != nil {
		if jsonData, err := json.Marshal(toVisitaResponse(*v)); err == nil {
			h.sseHub.Broadcast(jsonData)
		}
	}
}

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

	repoCtx := h.repo.WithContext(c.Request.Context())

	v, err := repoCtx.FindByIDAndKioskoID(uint(visitaID), uint(kioskoID))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "visita no encontrada"})
		return
	}

	h.aplicarExpiracionSiVencida(repoCtx, v)

	c.JSON(http.StatusOK, toVisitaResponse(*v))
}

func (h *Handler) GetVisitaByID(c *gin.Context) {
	adminID := c.MustGet(ctxkeys.AdminID).(uint)

	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID invalido"})
		return
	}

	repoCtx := h.repo.WithContext(c.Request.Context())

	v, err := repoCtx.FindByIDAndAdminID(uint(id), adminID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "visita no encontrada"})
		return
	}

	h.aplicarExpiracionSiVencida(repoCtx, v)

	c.JSON(http.StatusOK, toVisitaResponse(*v))
}

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

	repoCtx := h.repo.WithContext(c.Request.Context())

	list, total, err := repoCtx.FindAllByAdminID(adminID, filtros, page, pageSize)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	items := make([]VisitaListItemResponse, 0, len(list))
	for i := range list {
		h.aplicarExpiracionSiVencida(repoCtx, &list[i])
		items = append(items, toVisitaListItemResponse(list[i]))
	}

	c.JSON(http.StatusOK, VisitasPaginadasResponse{
		Visitas:  items,
		Total:    total,
		Page:     page,
		PageSize: pageSize,
	})
}

func (h *Handler) ActualizarEstado(c *gin.Context) {
	adminID := c.MustGet(ctxkeys.AdminID).(uint)

	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID invalido"})
		return
	}

	repoCtx := h.repo.WithContext(c.Request.Context())

	if _, err := repoCtx.FindByIDAndAdminID(uint(id), adminID); err != nil {
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

	if err := repoCtx.UpdateEstado(uint(id), estado); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"estado": string(estado)})
}

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

func (h *Handler) ListarReportes(c *gin.Context) {
	repoCtx := h.repo.WithContext(c.Request.Context())

	// Validamos que el db base use el scope por tenant al acceder a reportes_ia
	repo := &reporteRepository{db: repoCtx.db.Scopes(ByTenant)}
	reportes, err := repo.ultimos(7)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error obteniendo reportes"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"reportes": reportes})
}

func (h *Handler) HistorialVisita(c *gin.Context) {
	adminID := c.MustGet(ctxkeys.AdminID).(uint)

	curp := c.Query("curp")
	if curp == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "curp es requerido"})
		return
	}

	repoCtx := h.repo.WithContext(c.Request.Context())

	list, err := repoCtx.FindByCurpAndAdminID(curp, adminID)
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
