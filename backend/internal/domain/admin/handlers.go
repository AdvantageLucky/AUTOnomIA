package admin

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

// toAdminResponse mapea un Admin a su DTO de respuesta; Password nunca se incluye, queda fuera del DTO
func toAdminResponse(a *Admin) AdminResponse {
	return AdminResponse{
		ID:              a.ID,
		Nombre:          a.Nombre,
		ApellidoPaterno: a.ApellidoPaterno,
		ApellidoMaterno: a.ApellidoMaterno,
		Correo:          a.Correo,
	}
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

	hash, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	a := Admin{
		Nombre:          req.Nombre,
		ApellidoPaterno: req.ApellidoPaterno,
		ApellidoMaterno: req.ApellidoMaterno,
		Correo:          req.Correo,
		Password:        string(hash),
	}
	a.ID = uint(id)

	if err := h.repo.Update(&a); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, toAdminResponse(&a))
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
