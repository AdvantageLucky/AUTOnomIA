/*
Package residente

Handlers relacionados con el dominio residente
Hace uso del repository de residente

Documentado con swag
*/
package residente

import (
	"kigo-autonomia-backend/internal/domain/auth"
	"kigo-autonomia-backend/internal/platform/ctxkeys"
	"net/http"
	"strconv"

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

// LoginResidente autentica a un residente con kiosko_id + casa_destino + pin
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

	res, err := h.repo.FindByCasaAndKiosko(req.CasaDestino, req.KioskoID)
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
	adminID := c.MustGet(ctxkeys.AdminID).(uint)

	var req CrearResidenteRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := h.repo.VerificarOwnershipKiosko(req.KioskoID, adminID); err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "kiosko no encontrado"})
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
		KioskoID:        req.KioskoID,
	}

	if err := h.repo.Create(res); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, toResidenteResponse(*res))
}

// ListarResidentesPorAcceso lista residentes de un kiosko (admin dashboard)
//
// @Summary Listar residentes de un kiosko (admin)
// @Tags residente
// @Produce json
// @Param id path int true "ID del kiosko"
// @Success 200 {array} ResidenteResponse
// @Router /kioskos/{id}/residentes [get]
func (h *Handler) ListarResidentesPorAcceso(c *gin.Context) {
	adminID := c.MustGet(ctxkeys.AdminID).(uint)

	kioskoIDStr := c.Param("id")
	kioskoID, err := strconv.ParseUint(kioskoIDStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID invalido"})
		return
	}

	if err := h.repo.VerificarOwnershipKiosko(uint(kioskoID), adminID); err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "kiosko no encontrado"})
		return
	}

	list, err := h.repo.FindByKioskoID(uint(kioskoID))
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

// ListarResidentesAdmin lista todos los residentes de todos los kioskos del admin
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
