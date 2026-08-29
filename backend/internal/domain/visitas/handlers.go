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
	repo        *Repository
	uploadsDir  string
	llmURL      string
	sseHub      SseHub
	notificador Notificador
}

func NewHandler(repo *Repository, uploadsDir string, llmURL string, hub SseHub, notificador Notificador) *Handler {
	if notificador == nil {
		notificador = NotificadorNulo{}
	}
	return &Handler{repo: repo, uploadsDir: uploadsDir, llmURL: llmURL, sseHub: hub, notificador: notificador}
}

func kioskoSesionAutorizada(c *gin.Context, kioskoID uint) bool {
	sesionKioskoID := c.MustGet(ctxkeys.KioskoID).(uint)
	if sesionKioskoID != kioskoID {
		c.JSON(http.StatusForbidden, gin.H{"error": "la sesion no corresponde a este kiosko"})
		return false
	}
	return true
}

// ConsultarRecurrencia devuelve si un CURP tiene historial en el tenant y su última casa,
// para que el kiosko ofrezca el atajo de visitante recurrente. Autenticado por sesión de kiosko.
//
// @Summary Consultar recurrencia de un CURP
// @Description Indica si el CURP ya visitó antes y sugiere la última casa destino
// @Tags visitas
// @Produce json
// @Param id path int true "ID del kiosko"
// @Param curp query string true "CURP del visitante"
// @Success 200 {object} map[string]any
// @Failure 400 {object} map[string]string
// @Router /kioskos/{id}/visitas/recurrencia [get]
func (h *Handler) ConsultarRecurrencia(c *gin.Context) {
	kioskoID, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID de kiosko invalido"})
		return
	}
	if !kioskoSesionAutorizada(c, uint(kioskoID)) {
		return
	}

	curp := strings.ToUpper(strings.TrimSpace(c.Query("curp")))
	if curp == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "curp requerido"})
		return
	}

	historial, err := h.repo.WithContext(c.Request.Context()).HistorialPorCURP(curp)
	if err != nil || len(historial) == 0 {
		c.JSON(http.StatusOK, gin.H{"recurrente": false, "total_visitas": 0})
		return
	}

	// Solo cuentan las visitas que terminaron aprobadas: un CURP con puros
	// rechazos no merece el atajo de "bienvenido de nuevo".
	var aprobadas int
	var ultimaCasa string
	for _, v := range historial { // ya viene ordenado de más reciente a más antigua
		if v.Estado == EstadoAprobado {
			aprobadas++
			if ultimaCasa == "" {
				ultimaCasa = v.CasaDestino
			}
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"recurrente":    aprobadas > 0,
		"total_visitas": aprobadas,
		"ultima_casa":   ultimaCasa,
	})
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

	if req.ClientID != "" {
		existente, err := repoCtx.FindByClientID(tenantID, req.ClientID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		if existente != nil {
			c.JSON(http.StatusCreated, toVisitaResponse(*existente))
			return
		}
	}

	cfg, err := repoCtx.GetKioskoConfig(uint(kioskoID))
	if err != nil {
		c.JSON(
			http.StatusInternalServerError,
			gin.H{"error": "no se pudo obtener la configuracion del kiosko"},
		)
		return
	}

	tipoKiosko, err := repoCtx.GetKioskoTipo(uint(kioskoID))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "no se pudo obtener el tipo del kiosko"})
		return
	}

	if errMsg := ValidarCamposCondicionales(req, cfg, tipoKiosko); errMsg != "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": errMsg})
		return
	}

	var fotoDocumentoURL string
	if req.FotoDocumento != nil {
		fotoDocumentoURL, err = GuardarFotoVisitante(c, req.FotoDocumento, h.uploadsDir)
		if err != nil {
			if errors.Is(err, ErrFormatoFotoInvalido) {
				c.JSON(http.StatusBadRequest, gin.H{"error": "foto_documento: " + err.Error()})
				return
			}
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
	}

	var fotoRostroURL string
	if req.FotoRostro != nil {
		fotoRostroURL, err = GuardarFotoVisitante(c, req.FotoRostro, h.uploadsDir)
		if err != nil {
			if errors.Is(err, ErrFormatoFotoInvalido) {
				c.JSON(http.StatusBadRequest, gin.H{"error": "foto_rostro: " + err.Error()})
				return
			}
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
	}

	var fotoPlacaURL string
	if req.FotoPlaca != nil {
		fotoPlacaURL, err = GuardarFotoVisitante(c, req.FotoPlaca, h.uploadsDir)
		if err != nil {
			if errors.Is(err, ErrFormatoFotoInvalido) {
				c.JSON(http.StatusBadRequest, gin.H{"error": "foto_placa: " + err.Error()})
				return
			}
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
	}

	placa := strings.ToUpper(strings.TrimSpace(req.Placa))

	// Sin INE ni invitación no hay nombre que mostrar: la placa o el rostro hacen de titular
	titular := strings.ToUpper(strings.TrimSpace(req.Titular))
	if titular == "" {
		if placa != "" {
			titular = placa
		} else {
			titular = "VISITANTE"
		}
	}

	tipoDocumento := req.TipoDocumento
	if tipoDocumento == "" {
		if fotoRostroURL != "" {
			tipoDocumento = "ROSTRO"
		} else if placa != "" {
			tipoDocumento = DocumentoPlaca
		} else {
			tipoDocumento = "SIN_DOCUMENTO"
		}
	}

	v := &Visita{
		TenantID:         tenantID,
		Titular:          titular,
		TipoVisitante:    req.TipoVisitante,
		TipoDocumento:    tipoDocumento,
		Curp:             strings.ToUpper(strings.TrimSpace(req.Curp)),
		FotoDocumentoURL: fotoDocumentoURL,
		FotoRostroURL:    fotoRostroURL,
		FotoPlacaURL:     fotoPlacaURL,
		CasaDestino:      strings.ToUpper(strings.TrimSpace(req.CasaDestino)),
		Placa:            placa,
		Estado:           EstadoPendiente,
		KioskoID:         uint(kioskoID),
		ClientID:         ClientIDPtr(req.ClientID),
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

		historial, err := asyncRepo.HistorialDeVisitante(visitaCopy)
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

		tieneAnomalias := sc.AnomaliaMatricula || sc.CambioModalidad || sc.HorarioInusual ||
			sc.RechazadoPrevio || sc.OCRSospechoso

		nuevoEstado := EstadoPendiente
		if sc.Confiable && !tieneAnomalias && cfg.AutoPassHabilitado {
			nuevoEstado = EstadoAprobado
		} else if tieneAnomalias || (sc.Confiable && !cfg.AutoPassHabilitado) {
			nuevoEstado = EstadoRevision
		}

		scoreIA, _ := json.Marshal(sc.AScoreIA())
		var estadoParaGuardar *EstadoVisita
		if nuevoEstado != EstadoPendiente {
			estadoParaGuardar = &nuevoEstado
		}
		// Intervenida marca que la IA mando esta visita a revision por una
		// anomalia detectada -- NO se activa en auto-pass confiable (ahi no
		// hay nada que revisar) ni cuando el estado se decide por timeout en
		// otro lugar del codigo (aplicarExpiracionSiVencida, AutorizadorSistema),
		// que no pasa por este analisis.
		intervenida := nuevoEstado == EstadoRevision
		if err := asyncRepo.GuardarAnalisisIA(visitaCopy.ID, resumen, scoreIA, estadoParaGuardar, intervenida); err != nil {
			log.Printf("GuardarAnalisisIA visita %d: %v", visitaCopy.ID, err)
		}

		// A diferencia de antes, el broadcast dispara siempre que el análisis
		// termina (no solo si el estado cambió a REVISION/PENDIENTE) — el
		// dashboard en vivo necesita el resumen/score aunque la visita haya
		// quedado APROBADA por auto-pass.
		if h.sseHub != nil {
			visitaCopy.Estado = nuevoEstado
			visitaCopy.ResumenIA = resumen
			visitaCopy.ScoreIA = scoreIA
			if jsonData, err := json.Marshal(toVisitaResponse(visitaCopy)); err == nil {
				h.sseHub.Broadcast(jsonData)
			}
		}

		// Solo notificamos al anfitrión cuando de verdad necesita actuar — si el
		// agente ya la aprobó o la mandó a revisión de un vigilante, no le toca
		// decidir nada.
		if nuevoEstado == EstadoPendiente {
			// Timeout propio: el "ctx" de arriba ya se gastó (o casi) en la
			// llamada al LLM — reusarlo dejaría al notificador con muy poco o
			// nada de margen.
			notifCtx, notifCancel := context.WithTimeout(context.Background(), 5*time.Second)
			defer notifCancel()
			if err := h.notificador.NotificarNuevaVisita(notifCtx, tenantID, visitaCopy.CasaDestino, visitaCopy); err != nil {
				log.Printf("NotificarNuevaVisita visita %d: %v", visitaCopy.ID, err)
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

	tiempoEsperaSeg := cfg.TiempoEsperaSeg
	if tiempoEsperaSeg <= 0 {
		tiempoEsperaSeg = 90
	}

	limite := v.CreatedAt.Add(time.Duration(tiempoEsperaSeg) * time.Second)
	if time.Now().Before(limite) {
		return
	}

	if err := repoCtx.UpdateEstado(v.ID, EstadoRevision, AutorizadorSistema, ""); err != nil {
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

	item := toVisitaResponse(*v)
	if v.PersonaID != nil {
		if stats, err := repoCtx.EstadisticasPorPersona(*v.PersonaID); err == nil {
			item.Estadisticas = stats
		}
	}
	c.JSON(http.StatusOK, item)
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
	if tipoVisStr := c.Query("tipo_visitante"); tipoVisStr != "" {
		tv := TipoVisitante(tipoVisStr)
		if tv != TipoConInvitacion && tv != TipoSinInvitacion && tv != TipoResidente {
			c.JSON(http.StatusBadRequest, gin.H{"error": "tipo_visitante invalido"})
			return
		}
		filtros.TipoVisitante = &tv
	}
	if estadoStr := c.Query("estado"); estadoStr != "" {
		estado := EstadoVisita(estadoStr)
		if estado != EstadoPendiente && estado != EstadoAprobado && estado != EstadoRechazado && estado != EstadoRevision {
			c.JSON(http.StatusBadRequest, gin.H{"error": "estado invalido"})
			return
		}
		filtros.Estado = &estado
	}
	if intervenidaStr := c.Query("intervenida"); intervenidaStr != "" {
		val := intervenidaStr == "true"
		filtros.Intervenida = &val
	}
	if fechaStr := c.Query("fecha"); fechaStr != "" {
		ahora := time.Now()
		hoyInicio := time.Date(ahora.Year(), ahora.Month(), ahora.Day(), 0, 0, 0, 0, ahora.Location())
		switch fechaStr {
		case "hoy":
			filtros.FechaDesde = &hoyInicio
		case "ayer":
			ayerInicio := hoyInicio.AddDate(0, 0, -1)
			filtros.FechaDesde = &ayerInicio
			filtros.FechaHasta = &hoyInicio
		case "7d":
			desde := hoyInicio.AddDate(0, 0, -7)
			filtros.FechaDesde = &desde
		case "30d":
			desde := hoyInicio.AddDate(0, 0, -30)
			filtros.FechaDesde = &desde
		}
	}
	if personaIDStr := c.Query("persona_id"); personaIDStr != "" {
		if pid, err := strconv.ParseUint(personaIDStr, 10, 32); err == nil {
			pidUint := uint(pid)
			filtros.PersonaID = &pidUint
		}
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
		item := toVisitaListItemResponse(list[i])
		if list[i].PersonaID != nil {
			if stats, err := repoCtx.EstadisticasPorPersona(*list[i].PersonaID); err == nil {
				item.Estadisticas = stats
			}
		}
		items = append(items, item)
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

	nombre := fmt.Sprintf("admin #%d", adminID)
	if err := repoCtx.UpdateEstado(uint(id), estado, AutorizadorAdmin, nombre); err != nil {
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
