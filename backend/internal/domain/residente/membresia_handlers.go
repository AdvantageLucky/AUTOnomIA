package residente

import (
	"net/http"
	"strconv"

	"kigo-autonomia-backend/internal/platform/ctxkeys"

	"github.com/gin-gonic/gin"
)

// MembresiaHandler expone las acciones de admin sobre Membresia: aprobar o
// rechazar el ingreso de una Persona a este centro. Vive separado de
// Handler (que sigue siendo el dueño de Residente) para no mezclar los dos
// modelos de identidad en un mismo struct mientras coexistan (ver spec
// 2026-08-16-persona-identidad-kigo-design.md §11).
type MembresiaHandler struct {
	repo *MembresiaRepository
}

func NewMembresiaHandler(repo *MembresiaRepository) *MembresiaHandler {
	return &MembresiaHandler{repo: repo}
}

// ListarPendientes devuelve las membresías pendientes de aprobación del tenant del admin.
func (h *MembresiaHandler) ListarPendientes(c *gin.Context) {
	tenantID := c.MustGet(ctxkeys.TenantID).(uint)

	list, err := h.repo.FindPendientesPorTenant(tenantID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, list)
}

// Aprobar cambia el status de una membresía pendiente a activo.
func (h *MembresiaHandler) Aprobar(c *gin.Context) {
	tenantID := c.MustGet(ctxkeys.TenantID).(uint)

	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID inválido"})
		return
	}

	m, err := h.repo.FindByTenantAndID(tenantID, uint(id))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "membresía no encontrada"})
		return
	}
	if m.Status != ResidenteStatusPendiente {
		c.JSON(http.StatusConflict, gin.H{"error": "la membresía no está pendiente"})
		return
	}

	if err := h.repo.UpdateStatus(uint(id), ResidenteStatusActivo); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "membresía aprobada"})
}

// Rechazar cambia el status de una membresía a rechazado.
func (h *MembresiaHandler) Rechazar(c *gin.Context) {
	tenantID := c.MustGet(ctxkeys.TenantID).(uint)

	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID inválido"})
		return
	}

	m, err := h.repo.FindByTenantAndID(tenantID, uint(id))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "membresía no encontrada"})
		return
	}
	if m.Status == ResidenteStatusRechazado {
		c.JSON(http.StatusConflict, gin.H{"error": "la membresía ya fue rechazada"})
		return
	}

	if err := h.repo.UpdateStatus(uint(id), ResidenteStatusRechazado); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "membresía rechazada"})
}
