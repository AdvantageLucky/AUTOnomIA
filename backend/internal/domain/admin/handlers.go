/*
Package admin

Handlers relacionados con el dominio admin
Hace uso del repository relacionado a admin

Documentado con swag
*/
package admin

import (
	"kigo-autonomia-backend/internal/platform/ctxkeys"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"
)

type Handler struct {
	repo *Repository
}

func NewHandler(repo *Repository) *Handler {
	return &Handler{repo: repo}
}

// ListarAdmins devuelve todos los admins, filtrando por ?rol= si se proporciona
//
// @Summary Listar admins
// @Tags admins
// @Produce json
// @Param rol query string false "Filtrar por rol (admin, vigilante)"
// @Success 200
// @Router /admins [get]
func (h *Handler) ListarAdmins(c *gin.Context) {
	tenantID := c.MustGet(ctxkeys.TenantID).(uint)
	rol := c.Query("rol")
	admins, err := h.repo.FindAllByTenant(tenantID, rol)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error obteniendo admins"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"admins": admins})
}

// GetAdminByID busca un Admin por su ID
// Request: id uint (URL Param)
// Response: AdminResponse
//
// @Summary Obtener admin por ID
// @Description Busca un administrador por su ID
// @Tags admins
// @Produce json
// @Param id path int true "ID del admin"
// @Success 200 {object} AdminResponse
// @Failure 400 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Router /admins/{id} [get]
func (h *Handler) GetAdminByID(c *gin.Context) {
	adminID := c.MustGet(ctxkeys.AdminID).(uint)

	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID invalido"})
		return
	}

	if uint(id) != adminID {
		c.JSON(http.StatusForbidden, gin.H{"error": "no autorizado"})
		return
	}

	a, err := h.repo.FindByID(uint(id))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "admin no encontrado"})
		return
	}

	c.JSON(http.StatusOK, toAdminResponse(a))
}

// PatchAdmin modifica los datos de un Admin
// Request: id uint (URL Param) y AdminRequest
// Response: AdminResponse
//
// @Summary Modificar admin
// @Description Modifica los datos de un administrador, re-hasheando su password
// @Tags admins
// @Accept json
// @Produce json
// @Param id path int true "ID del admin"
// @Param admin body AdminRequest true "Datos a modificar"
// @Success 200 {object} AdminResponse
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /admins/{id} [patch]
func (h *Handler) PatchAdmin(c *gin.Context) {
	adminID := c.MustGet(ctxkeys.AdminID).(uint)

	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID invalido"})
		return
	}

	if uint(id) != adminID {
		c.JSON(http.StatusForbidden, gin.H{"error": "no autorizado"})
		return
	}

	var req AdminRequest
	if err = c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	existing, err := h.repo.FindByID(uint(id))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "admin no encontrado"})
		return
	}

	if req.Password != "" {
		hash, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		existing.Password = string(hash)
	}

	existing.Nombre = req.Nombre
	existing.ApellidoPaterno = req.ApellidoPaterno
	existing.ApellidoMaterno = req.ApellidoMaterno
	existing.Correo = req.Correo

	if err := h.repo.Update(existing); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, toAdminResponse(existing))
}

// DeleteAdmin elimina un Admin
// Request: id uint (URL Param)
// Response: ok msg
//
// @Summary Eliminar admin
// @Description Elimina un administrador
// @Tags admins
// @Produce json
// @Param id path int true "ID del admin"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /admins/{id} [delete]
func (h *Handler) DeleteAdmin(c *gin.Context) {
	adminID := c.MustGet(ctxkeys.AdminID).(uint)

	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID invalido"})
		return
	}

	if uint(id) != adminID {
		c.JSON(http.StatusForbidden, gin.H{"error": "no autorizado"})
		return
	}

	if err := h.repo.Delete(uint(id)); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "admin eliminado correctamente"})
}
