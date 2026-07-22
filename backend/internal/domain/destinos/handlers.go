/*
Package destinos

Handlers relacionados con el dominio destinos
Hace uso del repository de destinos

Documentado con swag
*/
package destinos

import (
	"kigo-autonomia-backend/internal/platform/ctxkeys"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
)

type Handler struct {
	repo *Repository
}

func NewHandler(repo *Repository) *Handler {
	return &Handler{repo: repo}
}

// ListarDestinosPorAcceso devuelve los destinos del kiosko autenticado
//
// @Summary Listar destinos (kiosko)
// @Description Devuelve todos los destinos del kiosko, incluyendo el titular de cada uno para verificación de IA
// @Tags destinos
// @Produce json
// @Param id path int true "ID del kiosko"
// @Success 200 {array} DestinoKioskoResponse
// @Router /kioskos/{id}/destinos [get]
func (h *Handler) ListarDestinosPorAcceso(c *gin.Context) {
	kioskoIDStr := c.Param("id")
	kioskoID, err := strconv.ParseUint(kioskoIDStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID de kiosko invalido"})
		return
	}

	// verifica que la sesion de kiosko corresponda al kiosko de la URL
	sesionKioskoID := c.MustGet(ctxkeys.KioskoID).(uint)
	if sesionKioskoID != uint(kioskoID) {
		c.JSON(http.StatusForbidden, gin.H{"error": "la sesion no corresponde a este kiosko"})
		return
	}

	list, err := h.repo.FindByKioskoID(uint(kioskoID))
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
// @Param id path int true "ID del kiosko"
// @Param body body DestinoAdminRequest true "Datos del destino"
// @Success 201 {object} DestinoKioskoResponse
// @Router /kioskos/{id}/destinos [post]
func (h *Handler) CrearDestino(c *gin.Context) {
	kioskoIDStr := c.Param("id")
	kioskoID, err := strconv.ParseUint(kioskoIDStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID de kiosko invalido"})
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
		KioskoID: uint(kioskoID),
	}

	if err := h.repo.Create(d); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, toDestinoKioskoResponse(*d))
}
