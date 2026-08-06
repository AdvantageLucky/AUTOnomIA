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

	repoCtx := h.repo.WithContext(c.Request.Context())

	list, err := repoCtx.FindByKioskoID(uint(kioskoID))
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

func (h *Handler) ListarDestinosPorAdmin(c *gin.Context) {
	adminID := c.MustGet(ctxkeys.AdminID).(uint)

	kioskoIDStr := c.Param("id")
	kioskoID, err := strconv.ParseUint(kioskoIDStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID de kiosko invalido"})
		return
	}

	repoCtx := h.repo.WithContext(c.Request.Context())

	if err := repoCtx.VerificarOwnershipAdmin(uint(kioskoID), adminID); err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "kiosko no encontrado"})
		return
	}

	list, err := repoCtx.FindByKioskoID(uint(kioskoID))
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

func (h *Handler) CrearDestino(c *gin.Context) {
	adminID := c.MustGet(ctxkeys.AdminID).(uint)
	tenantID := c.MustGet(ctxkeys.TenantID).(uint) // <-- EXTRAEMOS TENANT DEL CONTEXTO

	kioskoIDStr := c.Param("id")
	kioskoID, err := strconv.ParseUint(kioskoIDStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID de kiosko invalido"})
		return
	}

	repoCtx := h.repo.WithContext(c.Request.Context())

	if err := repoCtx.VerificarOwnershipAdmin(uint(kioskoID), adminID); err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "kiosko no encontrado"})
		return
	}

	var req DestinoAdminRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	d := &Destino{
		TenantID: tenantID, // <-- ASIGNAMOS TENANT PARA CUMPLIR LA REGLA NOT NULL
		Nombre:   req.Nombre,
		Titular:  req.Titular,
		KioskoID: uint(kioskoID),
	}

	if err := repoCtx.Create(d); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, toDestinoKioskoResponse(*d))
}

func (h *Handler) EliminarDestino(c *gin.Context) {
	adminID := c.MustGet(ctxkeys.AdminID).(uint)

	kioskoIDStr := c.Param("id")
	kioskoID, err := strconv.ParseUint(kioskoIDStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID de kiosko invalido"})
		return
	}

	repoCtx := h.repo.WithContext(c.Request.Context())

	if err := repoCtx.VerificarOwnershipAdmin(uint(kioskoID), adminID); err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "kiosko no encontrado"})
		return
	}

	destinoIDStr := c.Param("did")
	destinoID, err := strconv.ParseUint(destinoIDStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID de destino invalido"})
		return
	}

	if err := repoCtx.Delete(uint(destinoID), uint(kioskoID)); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.Status(http.StatusNoContent)
}
