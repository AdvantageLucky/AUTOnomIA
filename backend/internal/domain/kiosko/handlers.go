/*
Package kiosko

Handlers relacionados con el dominio kiosko
Hace uso del repository relacionado tambien a kiosko

Documentado con swag
*/
package kiosko

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strconv"
	"sync"

	"kigo-autonomia-backend/internal/platform/ctxkeys"
	"kigo-autonomia-backend/internal/platform/sse"

	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"
)

// configHubRegistry mantiene un hub SSE por kiosko para emitir cambios de config en tiempo real.
type configHubRegistry struct {
	mu   sync.RWMutex
	hubs map[uint]*sse.Hub
}

func (r *configHubRegistry) get(kioskoID uint) *sse.Hub {
	r.mu.RLock()
	h, ok := r.hubs[kioskoID]
	r.mu.RUnlock()
	if ok {
		return h
	}
	r.mu.Lock()
	defer r.mu.Unlock()
	if h, ok = r.hubs[kioskoID]; ok {
		return h
	}
	h = sse.NewHub()
	r.hubs[kioskoID] = h
	return h
}

type Handler struct {
	repo           *Repository
	cfgHubs        *configHubRegistry
	onKioskoDelete func(kioskoID uint) error // revoca sesiones al eliminar
}

func NewHandler(repo *Repository, onKioskoDelete func(uint) error) *Handler {
	return &Handler{
		repo:           repo,
		cfgHubs:        &configHubRegistry{hubs: make(map[uint]*sse.Hub)},
		onKioskoDelete: onKioskoDelete,
	}
}

// RegisterKiosko crea un nuevo Kiosko del Admin, generando su clave de kiosko
// Request: RegisterKioskoRequest
// Response: KioskoResponse (con clave_kiosko en texto plano, solo en esta respuesta)
//
// @Summary Registrar un kiosko
// @Description Registra un nuevo kiosko para el admin y genera su clave de kiosko (se devuelve en texto plano una sola vez, aqui)
// @Tags kioskos
// @Accept json
// @Produce json
// @Param kiosko body RegisterKioskoRequest true "Datos del kiosko"
// @Success 201 {object} KioskoResponse
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /kioskos [post]
func (h *Handler) RegisterKiosko(c *gin.Context) {
	adminID := c.MustGet(ctxkeys.AdminID).(uint)
	tenantID := c.MustGet(ctxkeys.TenantID).(uint)

	var req RegisterKioskoRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	claveKiosko, err := generateClaveKiosko()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(claveKiosko), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	a := &Kiosko{
		TenantID:    tenantID,
		Nombre:      req.Nombre,
		Tipo:        req.Tipo,
		Ubicacion:   req.Ubicacion,
		ClaveKiosko: string(hash),
		AdminID:     adminID,
	}

	if err := h.repo.WithContext(c.Request.Context()).Create(a); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	res := toKioskoResponse(a)
	res.ClaveKiosko = claveKiosko

	c.JSON(http.StatusCreated, res)
}

// GetKioskoByID busca un kiosko por su ID
// Request: id uint (URL Param)
// Response: KioskoResponse
//
// @Summary Obtener kiosko por ID
// @Description Busca un kiosko del admin autenticado por su ID
// @Tags kioskos
// @Produce json
// @Param id path int true "ID del kiosko"
// @Success 200 {object} KioskoResponse
// @Failure 400 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Router /kioskos/{id} [get]
func (h *Handler) GetKioskoByID(c *gin.Context) {
	adminID := c.MustGet(ctxkeys.AdminID).(uint)

	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID invalido"})
		return
	}

	a, err := h.repo.WithContext(c.Request.Context()).FindByIDAndAdminID(uint(id), adminID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "kiosko no encontrado"})
		return
	}

	c.JSON(http.StatusOK, toKioskoResponse(a))
}

// GetAllKioskos retorna todos los Kioskos del usuario
// Request:
// Response: []KioskoResponse
//
// @Summary Listar kioskos
// @Description Devuelve todos los kioskos del admin autenticado
// @Tags kioskos
// @Produce json
// @Success 200 {array} KioskoResponse
// @Failure 500 {object} map[string]string
// @Router /kioskos [get]
func (h *Handler) GetAllKioskos(c *gin.Context) {
	adminID := c.MustGet(ctxkeys.AdminID).(uint)

	kioskos, err := h.repo.WithContext(c.Request.Context()).FindAllByAdminID(adminID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	res := make([]KioskoResponse, 0, len(kioskos))
	for i := range kioskos {
		res = append(res, toKioskoResponse(&kioskos[i]))
	}

	c.JSON(http.StatusOK, res)
}

// PatchKiosko modifica el nombre o ubicacion de un kiosko
// Request: id uint (URL Param) y RegisterKioskoRequest
// Response: KioskoResponse
//
// @Summary Modificar kiosko
// @Description Modifica el nombre o ubicacion de un kiosko del admin autenticado
// @Tags kioskos
// @Accept json
// @Produce json
// @Param id path int true "ID del kiosko"
// @Param kiosko body RegisterKioskoRequest true "Datos a modificar"
// @Success 200 {object} KioskoResponse
// @Failure 400 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /kioskos/{id} [patch]
func (h *Handler) PatchKiosko(c *gin.Context) {
	adminID := c.MustGet(ctxkeys.AdminID).(uint)

	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID invalido"})
		return
	}

	var req RegisterKioskoRequest
	if err = c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	repoCtx := h.repo.WithContext(c.Request.Context())

	a, err := repoCtx.FindByIDAndAdminID(uint(id), adminID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "kiosko no encontrado"})
		return
	}

	tipoAnterior := a.Tipo

	a.Nombre = req.Nombre
	a.Tipo = req.Tipo
	a.Ubicacion = req.Ubicacion

	if err := repoCtx.Update(a, adminID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, toKioskoResponse(a))

	if tipoAnterior == a.Tipo {
		return
	}

	// El tipo cambio: la app del kiosko lo recibe por el stream de config y cambia
	// de flujo sin reiniciar. Al pasar a peatonal se apagan los toggles de placa,
	// que PatchConfig ya prohibe para ese tipo y el flujo peatonal no puede cumplir.
	cfg, err := repoCtx.FindConfigByKioskoID(uint(id))
	if err != nil {
		return
	}

	if a.Tipo == KioskoPeatonal && (cfg.FotoPlacaVisitante || cfg.FotoPlacaInvitado) {
		cfg.FotoPlacaVisitante = false
		cfg.FotoPlacaInvitado = false
		if err := repoCtx.UpdateConfig(cfg); err != nil {
			return
		}
	}

	if data, err := json.Marshal(toKioskoConfigResponse(cfg, a.Tipo)); err == nil {
		h.cfgHubs.get(cfg.KioskoID).Broadcast(data)
	}
}

// DeleteKiosko elimina un kiosko
// Request: id uint (URL Param)
// Response: ok msg
//
// @Summary Eliminar kiosko
// @Description Elimina un kiosko del admin autenticado
// @Tags kioskos
// @Produce json
// @Param id path int true "ID del kiosko"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /kioskos/{id} [delete]
func (h *Handler) DeleteKiosko(c *gin.Context) {
	adminID := c.MustGet(ctxkeys.AdminID).(uint)

	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID invalido"})
		return
	}

	if err := h.repo.WithContext(c.Request.Context()).Delete(uint(id), adminID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	if h.onKioskoDelete != nil {
		_ = h.onKioskoDelete(uint(id))
	}

	c.JSON(http.StatusOK, gin.H{"message": "kiosko eliminado correctamente"})
}

// GetConfig devuelve la configuración del kiosko
//
// @Summary Obtener configuración de kiosko
// @Description Devuelve la KioskoConfig del kiosko; la crea con valores por defecto si no existía
// @Tags kioskos
// @Produce json
// @Param id path int true "ID del kiosko"
// @Success 200 {object} KioskoConfigResponse
// @Failure 400 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /kioskos/{id}/config [get]
func (h *Handler) GetConfig(c *gin.Context) {
	adminID := c.MustGet(ctxkeys.AdminID).(uint)

	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID invalido"})
		return
	}

	repoCtx := h.repo.WithContext(c.Request.Context())

	kiosko, err := repoCtx.FindByIDAndAdminID(uint(id), adminID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "kiosko no encontrado"})
		return
	}

	cfg, err := repoCtx.FindConfigByKioskoID(uint(id))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, toKioskoConfigResponse(cfg, kiosko.Tipo))
}

// GetConfigDesdeKiosko devuelve la config del kiosko autenticado por su propia sesión
// (no requiere admin). Usado por la app del kiosko para cargar su configuración inicial.
func (h *Handler) GetConfigDesdeKiosko(c *gin.Context) {
	kioskoID := c.MustGet(ctxkeys.KioskoID).(uint)

	repoCtx := h.repo.WithContext(c.Request.Context())
	cfg, err := repoCtx.FindConfigByKioskoID(kioskoID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// el tipo decide si la app monta el flujo peatonal o el vehicular
	kiosko, err := repoCtx.FindByID(kioskoID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, toKioskoConfigResponse(cfg, kiosko.Tipo))
}

// PatchConfig actualiza los campos indicados de la config del kiosko (PATCH parcial)
//
// @Summary Actualizar configuración de kiosko
// @Description Actualiza parcialmente la KioskoConfig; solo se modifican los campos presentes en el body
// @Tags kioskos
// @Accept json
// @Produce json
// @Param id path int true "ID del kiosko"
// @Param config body KioskoConfigRequest true "Campos a actualizar (todos opcionales)"
// @Success 200 {object} KioskoConfigResponse
// @Failure 400 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /kioskos/{id}/config [patch]
func (h *Handler) PatchConfig(c *gin.Context) {
	adminID := c.MustGet(ctxkeys.AdminID).(uint)

	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID invalido"})
		return
	}

	repoCtx := h.repo.WithContext(c.Request.Context())

	kiosko, err := repoCtx.FindByIDAndAdminID(uint(id), adminID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "kiosko no encontrado"})
		return
	}

	var req KioskoConfigRequest
	if err = c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if kiosko.Tipo == KioskoPeatonal {
		if req.FotoPlacaVisitante != nil && *req.FotoPlacaVisitante {
			c.JSON(http.StatusBadRequest, gin.H{"error": "foto_placa_visitante no aplica a kioskos peatonales"})
			return
		}
		if req.FotoPlacaInvitado != nil && *req.FotoPlacaInvitado {
			c.JSON(http.StatusBadRequest, gin.H{"error": "foto_placa_invitado no aplica a kioskos peatonales"})
			return
		}
	}

	cfg, err := repoCtx.FindConfigByKioskoID(uint(id))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	if req.ColorKiosko != nil {
		cfg.ColorKiosko = *req.ColorKiosko
	}
	if req.IdiomaKiosko != nil {
		cfg.IdiomaKiosko = *req.IdiomaKiosko
	}
	if req.FotoPlacaVisitante != nil {
		cfg.FotoPlacaVisitante = *req.FotoPlacaVisitante
	}
	if req.FotoRostroVisitante != nil {
		cfg.FotoRostroVisitante = *req.FotoRostroVisitante
	}
	if req.FotoPlacaInvitado != nil {
		cfg.FotoPlacaInvitado = *req.FotoPlacaInvitado
	}
	if req.FotoRostroInvitado != nil {
		cfg.FotoRostroInvitado = *req.FotoRostroInvitado
	}
	if req.IneObligatorioInvitado != nil {
		cfg.IneObligatorioInvitado = *req.IneObligatorioInvitado
	}
	if req.TiempoEsperaSeg != nil {
		cfg.TiempoEsperaSeg = *req.TiempoEsperaSeg
	}
	if req.HorarioInicio != nil {
		cfg.HorarioInicio = *req.HorarioInicio
	}
	if req.HorarioFin != nil {
		cfg.HorarioFin = *req.HorarioFin
	}
	if req.MensajeBienvenida != nil {
		cfg.MensajeBienvenida = *req.MensajeBienvenida
	}
	if req.AutoPassHabilitado != nil {
		cfg.AutoPassHabilitado = *req.AutoPassHabilitado
	}
	if req.UmbralConfianzaVisitas != nil {
		cfg.UmbralConfianzaVisitas = *req.UmbralConfianzaVisitas
	}
	if req.UmbralSimilitudCara != nil {
		cfg.UmbralSimilitudCara = *req.UmbralSimilitudCara
	}

	if err := repoCtx.UpdateConfig(cfg); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	resp := toKioskoConfigResponse(cfg, kiosko.Tipo)
	c.JSON(http.StatusOK, resp)

	if data, err := json.Marshal(resp); err == nil {
		h.cfgHubs.get(cfg.KioskoID).Broadcast(data)
	}
}

// StreamConfig abre una conexión SSE y emite la config cada vez que el admin la actualiza.
//
// @Summary Stream SSE de config del kiosko
// @Tags kioskos
// @Produce text/event-stream
// @Param id path int true "ID del kiosko"
// @Success 200
// @Router /kioskos/{id}/config/stream [get]
func (h *Handler) StreamConfig(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID invalido"})
		return
	}

	c.Header("Content-Type", "text/event-stream")
	c.Header("Cache-Control", "no-cache")
	c.Header("Connection", "keep-alive")
	c.Header("X-Accel-Buffering", "no")

	hub := h.cfgHubs.get(uint(id))
	ch := hub.Subscribe()
	defer hub.Unsubscribe(ch)

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
