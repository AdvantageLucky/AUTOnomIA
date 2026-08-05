package tenant

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
)

type Handler struct {
	repo Repository
}

func NewHandler(repo Repository) *Handler {
	return &Handler{repo: repo}
}

func (h *Handler) CreateTenant(c *gin.Context) {
	var req CreateTenantRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	nuevoTenant := CentroHabitacional{
		Nombre:    req.Nombre,
		Direccion: req.Direccion,
	}

	if err := h.repo.Create(&nuevoTenant); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error al crear fraccionamiento"})
		return
	}

	c.JSON(http.StatusCreated, TenantResponse{
		ID:        nuevoTenant.ID,
		Nombre:    nuevoTenant.Nombre,
		Direccion: nuevoTenant.Direccion,
		CreatedAt: nuevoTenant.CreatedAt,
	})
}

func (h *Handler) GetTenant(c *gin.Context) {
	idParam := c.Param("id")
	id, err := strconv.ParseUint(idParam, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID inválido"})
		return
	}

	tenant, err := h.repo.FindByID(uint(id))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, TenantResponse{
		ID:        tenant.ID,
		Nombre:    tenant.Nombre,
		Direccion: tenant.Direccion,
		CreatedAt: tenant.CreatedAt,
	})
}
