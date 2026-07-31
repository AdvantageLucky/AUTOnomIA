/*
Package kiosko

Handlers relacionados con el dominio kiosko
Hace uso del repository relacionado tambien a kiosko

Documentado con swag
*/
package kiosko

import (
	"net/http"
	"strconv"

	"kigo-autonomia-backend/internal/platform/ctxkeys"

	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"
)

type Handler struct {
	repo *Repository
}

func NewHandler(repo *Repository) *Handler {
	return &Handler{repo: repo}
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

	var req RegisterKioskoRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// generamos la clave kiosko aleatoria
	claveKiosko, err := generateClaveKiosko()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// hasheamos con salt la clave
	hash, err := bcrypt.GenerateFromPassword([]byte(claveKiosko), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// creamos el kiosko y retornamos
	a := &Kiosko{
		Nombre:      req.Nombre,
		Tipo:        req.Tipo,
		Ubicacion:   req.Ubicacion,
		ClaveKiosko: string(hash),
		AdminID:     adminID,
	}

	if err := h.repo.Create(a); err != nil {
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

	a, err := h.repo.FindByIDAndAdminID(uint(id), adminID)
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

	kioskos, err := h.repo.FindAllByAdminID(adminID)
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

// PatchKiosko modifica el nombre o ubicacion de un kiosko (la clave de kiosko no se toca aqui)
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

	// cargamos el kiosko existente para conservar su ClaveKiosko: Update hace un Save() de
	// fila completa, y RegisterKioskoRequest ya no trae clave_kiosko (la genera el servidor una sola vez)
	a, err := h.repo.FindByIDAndAdminID(uint(id), adminID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "kiosko no encontrado"})
		return
	}

	a.Nombre = req.Nombre
	a.Tipo = req.Tipo
	a.Ubicacion = req.Ubicacion

	if err := h.repo.Update(a, adminID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, toKioskoResponse(a))
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

	if err := h.repo.Delete(uint(id), adminID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
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

	if _, err = h.repo.FindByIDAndAdminID(uint(id), adminID); err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "kiosko no encontrado"})
		return
	}

	cfg, err := h.repo.FindConfigByKioskoID(uint(id))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, toKioskoConfigResponse(cfg))
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

	kiosko, err := h.repo.FindByIDAndAdminID(uint(id), adminID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "kiosko no encontrado"})
		return
	}

	var req KioskoConfigRequest
	if err = c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// al patchear la configuracion del kiosko, si este es de tipo peatonal entonces
	// se sobreescribe la configuracion de placa visitante para no pedir placa.
	// En UI esta parte se oculta pero este es un doble filtro a la request
	if kiosko.Tipo == KioskoPeatonal {
		if req.FotoPlacaVisitante != nil && *req.FotoPlacaVisitante {
			c.JSON(
				http.StatusBadRequest,
				gin.H{"error": "foto_placa_visitante no aplica a kioskos peatonales"},
			)
			return
		}
		if req.FotoPlacaInvitado != nil && *req.FotoPlacaInvitado {
			c.JSON(
				http.StatusBadRequest,
				gin.H{"error": "foto_placa_invitado no aplica a kioskos peatonales"},
			)
			return
		}
	}

	cfg, err := h.repo.FindConfigByKioskoID(uint(id))
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
	if req.TiempoEsperaMin != nil {
		cfg.TiempoEsperaMin = *req.TiempoEsperaMin
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

	if err := h.repo.UpdateConfig(cfg); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, toKioskoConfigResponse(cfg))
}
