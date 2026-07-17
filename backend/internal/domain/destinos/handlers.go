package destinos

import (
	"net/http"
	"strconv"

	"kigo-autonomia-backend/internal/platform/ctxkeys"

	"github.com/gin-gonic/gin"
)

type Handler struct {
	repo *Repository
}

func NewHandler(repo *Repository) *Handler {
	return &Handler{repo: repo}
}

// ListarDestinosPorAcceso devuelve los destinos del acceso del kiosko autenticado
//
// @Summary Listar destinos (kiosko)
// @Description Devuelve todos los destinos del acceso, incluyendo el titular de cada uno para verificación de IA
// @Tags destinos
// @Produce json
// @Param id path int true "ID del acceso"
// @Success 200 {array} DestinoKioskoResponse
// @Router /accesos/{id}/destinos [get]
func (h *Handler) ListarDestinosPorAcceso(c *gin.Context) {
	accesoIDStr := c.Param("id")
	accesoID, err := strconv.ParseUint(accesoIDStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID de acceso invalido"})
		return
	}

	// verifica que la sesion de kiosko corresponda al acceso de la URL
	sesionAccesoID := c.MustGet(ctxkeys.AccesoID).(uint)
	if sesionAccesoID != uint(accesoID) {
		c.JSON(http.StatusForbidden, gin.H{"error": "la sesion no corresponde a este acceso"})
		return
	}

	list, err := h.repo.FindByAccesoID(uint(accesoID))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	items := make([]DestinoKioskoResponse, 0, len(list))
	for _, d := range list {
		items = append(items, toDestinoKioskoResponse(d))
	}

	c.JSON(http.StatusOK, items)
}

// CrearDestino crea un destino (admin dashboard)
//
// @Summary Crear destino (admin)
// @Tags destinos
// @Accept json
// @Produce json
// @Param id path int true "ID del acceso"
// @Param body body DestinoAdminRequest true "Datos del destino"
// @Success 201 {object} DestinoKioskoResponse
// @Router /accesos/{id}/destinos [post]
func (h *Handler) CrearDestino(c *gin.Context) {
	accesoIDStr := c.Param("id")
	accesoID, err := strconv.ParseUint(accesoIDStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID de acceso invalido"})
		return
	}

	var req DestinoAdminRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	d := &Destino{
		Nombre:   req.Nombre,
		Titular:  req.Titular,
		AccesoID: uint(accesoID),
	}

	if err := h.repo.Create(d); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, toDestinoKioskoResponse(*d))
}
