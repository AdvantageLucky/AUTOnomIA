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

func tenantFromCtx(c *gin.Context) (uint, bool) {
	v, exists := c.Get(ctxkeys.TenantID)
	if !exists {
		return 0, false
	}
	id, ok := v.(uint)
	return id, ok && id > 0
}

// ListarDestinosPorAcceso — kiosko: lista todos los destinos del tenant
func (h *Handler) ListarDestinosPorAcceso(c *gin.Context) {
	kioskoIDStr := c.Param("id")
	kioskoID, err := strconv.ParseUint(kioskoIDStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID de kiosko invalido"})
		return
	}

	sesionKioskoID := c.MustGet(ctxkeys.KioskoID).(uint)
	if sesionKioskoID != uint(kioskoID) {
		c.JSON(http.StatusForbidden, gin.H{"error": "la sesion no corresponde a este kiosko"})
		return
	}

	tenantID, ok := tenantFromCtx(c)
	if !ok {
		c.JSON(http.StatusForbidden, gin.H{"error": "tenant no resuelto"})
		return
	}

	list, err := h.repo.WithContext(c.Request.Context()).FindByTenantID(tenantID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	items := make([]DestinoResponse, 0, len(list))
	for _, d := range list {
		items = append(items, toDestinoResponse(d))
	}
	c.JSON(http.StatusOK, items)
}

// ListarDestinos — admin: lista todos los destinos del tenant
func (h *Handler) ListarDestinos(c *gin.Context) {
	tenantID, ok := tenantFromCtx(c)
	if !ok {
		c.JSON(http.StatusForbidden, gin.H{"error": "tenant no resuelto"})
		return
	}

	list, err := h.repo.WithContext(c.Request.Context()).FindByTenantID(tenantID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	items := make([]DestinoResponse, 0, len(list))
	for _, d := range list {
		items = append(items, toDestinoResponse(d))
	}
	c.JSON(http.StatusOK, items)
}

// CrearDestino — admin: crea un destino a nivel del tenant
func (h *Handler) CrearDestino(c *gin.Context) {
	tenantID, ok := tenantFromCtx(c)
	if !ok {
		c.JSON(http.StatusForbidden, gin.H{"error": "tenant no resuelto"})
		return
	}

	var req DestinoAdminRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	d := &Destino{
		TenantID: tenantID,
		Nombre:   req.Nombre,
		Titular:  req.Titular,
	}

	if err := h.repo.WithContext(c.Request.Context()).Create(d); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, toDestinoResponse(*d))
}

// EliminarDestino — admin: elimina un destino del tenant
func (h *Handler) EliminarDestino(c *gin.Context) {
	tenantID, ok := tenantFromCtx(c)
	if !ok {
		c.JSON(http.StatusForbidden, gin.H{"error": "tenant no resuelto"})
		return
	}

	destinoIDStr := c.Param("id")
	destinoID, err := strconv.ParseUint(destinoIDStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID de destino invalido"})
		return
	}

	if err := h.repo.WithContext(c.Request.Context()).Delete(uint(destinoID), tenantID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.Status(http.StatusNoContent)
}
