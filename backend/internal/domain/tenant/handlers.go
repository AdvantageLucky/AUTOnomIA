package tenant

import (
	"net/http"
	"strconv"
	"strings"

	"kigo-autonomia-backend/internal/platform/ctxkeys"

	"github.com/gin-gonic/gin"
)

type Handler struct {
	repo Repository
}

func NewHandler(repo Repository) *Handler {
	return &Handler{repo: repo}
}

func (h *Handler) GetTenant(c *gin.Context) {
	id, err := parseID(c, "id")
	if err != nil {
		return
	}

	if !esTenantPropio(c, id) {
		c.JSON(http.StatusForbidden, gin.H{"error": "no autorizado"})
		return
	}

	t, err := h.repo.FindByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, toResponse(t))
}

func (h *Handler) PatchTenant(c *gin.Context) {
	id, err := parseID(c, "id")
	if err != nil {
		return
	}

	if !esTenantPropio(c, id) {
		c.JSON(http.StatusForbidden, gin.H{"error": "no autorizado"})
		return
	}

	var req UpdateTenantRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	fields := map[string]any{}
	if req.Nombre != "" {
		fields["nombre"] = req.Nombre
	}
	if req.Direccion != "" {
		fields["direccion"] = req.Direccion
	}
	if req.Codigo != "" {
		fields["codigo"] = req.Codigo
	}
	if req.Tipo != "" {
		fields["tipo"] = req.Tipo
	}
	fields["descripcion"] = req.Descripcion

	if err := h.repo.Update(id, fields); err != nil {
		msg := err.Error()
		if strings.Contains(msg, "duplicate key") || strings.Contains(msg, "23505") {
			c.JSON(http.StatusConflict, gin.H{"error": "Ese código ya está en uso por otra instalación"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error actualizando instalación"})
		return
	}

	t, _ := h.repo.FindByID(id)
	c.JSON(http.StatusOK, toResponse(t))
}

func toResponse(t *CentroHabitacional) TenantResponse {
	return TenantResponse{
		ID:          t.ID,
		Nombre:      t.Nombre,
		Direccion:   t.Direccion,
		Codigo:      t.Codigo,
		Tipo:        t.Tipo,
		Descripcion: t.Descripcion,
		CreatedAt:   t.CreatedAt,
	}
}

// esTenantPropio verifica que el id de la ruta coincida con el tenant_id del
// admin autenticado (inyectado por auth.RequireAdmin vía JWT).
func esTenantPropio(c *gin.Context, id uint) bool {
	tenantID := c.MustGet(ctxkeys.TenantID).(uint)
	return tenantID == id
}

func parseID(c *gin.Context, param string) (uint, error) {
	v, err := strconv.ParseUint(c.Param(param), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID inválido"})
		return 0, err
	}
	return uint(v), nil
}
