package tenant

import (
	"errors"
	"fmt"
	"net/http"
	"strconv"
	"strings"

	"kigo-autonomia-backend/internal/platform/ctxkeys"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
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
	if strings.TrimSpace(req.TelefonoContacto) == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "El teléfono de contacto es requerido"})
		return
	}

	actual, err := h.repo.FindByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}

	fields := map[string]any{}
	if req.Nombre != "" {
		fields["nombre"] = req.Nombre
	}
	if req.Direccion != "" {
		fields["direccion"] = req.Direccion
	}
	fields["descripcion"] = req.Descripcion
	fields["telefono_contacto"] = req.TelefonoContacto

	// El código se deriva del nombre y el admin nunca lo escribe directamente
	// -- se regenera cuando el nombre cambia (o no existe todavía) para que
	// siga reflejando el nombre actual del centro. Esto no rompe a los
	// residentes ya vinculados: Membresia referencia al centro por su ID
	// numérico, no por este código -- solo un enlace de invitación sin usar
	// compartido con el código viejo dejaría de servir.
	if req.Nombre != "" && (actual.Codigo == nil || *actual.Codigo == "" || req.Nombre != actual.Nombre) {
		fields["codigo"] = h.generarCodigoUnico(req.Nombre, actual.ID)
	}

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

// generarCodigoUnico deriva el código del nombre y le agrega un sufijo
// numérico si ya está en uso por otro centro (Codigo es uniqueIndex).
// excludeID es el propio centro que se está actualizando -- si el código
// derivado coincide con el que ya tenía asignado, no cuenta como colisión.
func (h *Handler) generarCodigoUnico(nombre string, excludeID uint) string {
	base := GenerarCodigo(nombre)
	codigo := base
	for i := 2; ; i++ {
		existente, err := h.repo.FindByCodigo(codigo)
		if errors.Is(err, gorm.ErrRecordNotFound) || existente.ID == excludeID {
			return codigo
		}
		codigo = fmt.Sprintf("%s-%d", base, i)
	}
}

func toResponse(t *CentroHabitacional) TenantResponse {
	codigo := ""
	if t.Codigo != nil {
		codigo = *t.Codigo
	}
	return TenantResponse{
		ID:               t.ID,
		Nombre:           t.Nombre,
		Direccion:        t.Direccion,
		Codigo:           codigo,
		Descripcion:      t.Descripcion,
		TelefonoContacto: t.TelefonoContacto,
		CreatedAt:        t.CreatedAt,
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
