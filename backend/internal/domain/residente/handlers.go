package residente

import (
	"net/http"
	"strconv"

	"kigo-autonomia-backend/internal/domain/auth"
	"kigo-autonomia-backend/internal/platform/ctxkeys"

	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"
)

type Handler struct {
	repo      *Repository
	jwtSecret string
}

func NewHandler(repo *Repository, jwtSecret string) *Handler {
	return &Handler{repo: repo, jwtSecret: jwtSecret}
}

// LoginResidente autentica a un residente con acceso_id + casa_destino + pin
//
// @Summary Login del residente
// @Tags residente
// @Accept json
// @Produce json
// @Param body body LoginResidenteRequest true "Credenciales"
// @Success 200 {object} auth.JWTResponse
// @Router /auth/residente/login [post]
func (h *Handler) LoginResidente(c *gin.Context) {
	var req LoginResidenteRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "campos incorrectos"})
		return
	}

	res, err := h.repo.FindByCasaAndAcceso(req.CasaDestino, req.AccesoID)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "residente no encontrado"})
		return
	}

	if err := bcrypt.CompareHashAndPassword([]byte(res.Pin), []byte(req.Pin)); err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "pin incorrecto"})
		return
	}

	token, err := auth.GenerateResidenteToken(res.ID, h.jwtSecret)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, auth.JWTResponse{AccessToken: token})
}

// GetMe devuelve el perfil del residente autenticado
//
// @Summary Perfil del residente
// @Tags residente
// @Produce json
// @Success 200 {object} ResidenteResponse
// @Router /residentes/me [get]
func (h *Handler) GetMe(c *gin.Context) {
	residenteID := c.MustGet(ctxkeys.ResidenteID).(uint)

	res, err := h.repo.FindByID(residenteID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "residente no encontrado"})
		return
	}

	c.JSON(http.StatusOK, toResidenteResponse(*res))
}

// CrearResidente crea un residente (admin dashboard)
//
// @Summary Crear residente (admin)
// @Tags residente
// @Accept json
// @Produce json
// @Param body body CrearResidenteRequest true "Datos del residente"
// @Success 201 {object} ResidenteResponse
// @Router /residentes [post]
func (h *Handler) CrearResidente(c *gin.Context) {
	var req CrearResidenteRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(req.Pin), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	res := &Residente{
		Nombre:          req.Nombre,
		ApellidoPaterno: req.ApellidoPaterno,
		ApellidoMaterno: req.ApellidoMaterno,
		Pin:             string(hash),
		CasaDestino:     req.CasaDestino,
		Telefono:        req.Telefono,
		AccesoID:        req.AccesoID,
	}

	if err := h.repo.Create(res); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, toResidenteResponse(*res))
}

// ListarResidentesPorAcceso lista residentes de un acceso (admin dashboard)
//
// @Summary Listar residentes de un acceso (admin)
// @Tags residente
// @Produce json
// @Param id path int true "ID del acceso"
// @Success 200 {array} ResidenteResponse
// @Router /accesos/{id}/residentes [get]
func (h *Handler) ListarResidentesPorAcceso(c *gin.Context) {
	accesoIDStr := c.Param("id")
	accesoID, err := strconv.ParseUint(accesoIDStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID invalido"})
		return
	}

	list, err := h.repo.FindByAccesoID(uint(accesoID))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	items := make([]ResidenteResponse, 0, len(list))
	for _, r := range list {
		items = append(items, toResidenteResponse(r))
	}

	c.JSON(http.StatusOK, items)
}

// ListarResidentesAdmin lista todos los residentes de todos los accesos del admin
func (h *Handler) ListarResidentesAdmin(c *gin.Context) {
	adminID := c.MustGet(ctxkeys.AdminID).(uint)

	list, err := h.repo.FindAllByAdminID(adminID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	items := make([]ResidenteResponse, 0, len(list))
	for _, r := range list {
		items = append(items, toResidenteResponse(r))
	}

	c.JSON(http.StatusOK, items)
}
