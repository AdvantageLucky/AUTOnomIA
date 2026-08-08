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

	t := CentroHabitacional{
		Nombre:    req.Nombre,
		Direccion: req.Direccion,
	}
	if err := h.repo.Create(&t); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error al crear instalación"})
		return
	}

	c.JSON(http.StatusCreated, toResponse(&t))
}

func (h *Handler) GetTenant(c *gin.Context) {
	id, err := parseID(c, "id")
	if err != nil {
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

func parseID(c *gin.Context, param string) (uint, error) {
	v, err := strconv.ParseUint(c.Param(param), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID inválido"})
		return 0, err
	}
	return uint(v), nil
}
