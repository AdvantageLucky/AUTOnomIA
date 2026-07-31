package invitaciones

import (
	"crypto/rand"
	"encoding/hex"
	"errors"
	"net/http"
	"strconv"

	"kigo-autonomia-backend/internal/domain/visitas"
	"kigo-autonomia-backend/internal/platform/ctxkeys"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type Handler struct {
	repo *Repository
	db   *gorm.DB
}

func NewHandler(repo *Repository, db *gorm.DB) *Handler {
	return &Handler{repo: repo, db: db}
}



func generarToken() (string, error) {
	b := make([]byte, 32)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	return hex.EncodeToString(b), nil
}

// CrearInvitacion crea una invitación y devuelve el token
//
// @Summary Crear invitación
// @Tags invitaciones
// @Accept json
// @Produce json
// @Param body body CreateInvitacionRequest true "Datos de la invitación"
// @Success 201 {object} InvitacionResponse
// @Failure 400 {object} map[string]string
// @Router /residentes/me/invitaciones [post]
func (h *Handler) CrearInvitacion(c *gin.Context) {
	residenteID := c.MustGet(ctxkeys.ResidenteID).(uint)

	var req CreateInvitacionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	token, err := generarToken()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error generando token"})
		return
	}

	inv := &Invitacion{
		Token:       token,
		Tipo:        req.Tipo,
		Titular:     req.Titular,
		ResidenteID: residenteID,
		DestinoID:   req.DestinoID,
		MaxUsos:     req.MaxUsos,
		ExpiresAt:   req.ExpiresAt,
	}

	if err := h.repo.Create(inv); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, toInvitacionResponse(inv, true))
}

// ListarInvitaciones lista las invitaciones activas del residente autenticado
//
// @Summary Listar invitaciones
// @Tags invitaciones
// @Produce json
// @Success 200 {array} InvitacionResponse
// @Router /residentes/me/invitaciones [get]
func (h *Handler) ListarInvitaciones(c *gin.Context) {
	residenteID := c.MustGet(ctxkeys.ResidenteID).(uint)

	list, err := h.repo.FindByResidenteID(residenteID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	resp := make([]InvitacionResponse, len(list))
	for i, inv := range list {
		resp[i] = toInvitacionResponse(&inv, false)
	}
	c.JSON(http.StatusOK, resp)
}

// RevocarInvitacion revoca (soft-delete) una invitacion del residente
//
// @Summary Revocar invitación
// @Tags invitaciones
// @Produce json
// @Param id path int true "ID de la invitación"
// @Success 200 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Router /residentes/me/invitaciones/{id} [delete]
func (h *Handler) RevocarInvitacion(c *gin.Context) {
	residenteID := c.MustGet(ctxkeys.ResidenteID).(uint)

	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID invalido"})
		return
	}

	if err := h.repo.RevocarByID(uint(id), residenteID); err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			c.JSON(http.StatusNotFound, gin.H{"error": "invitacion no encontrada"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "invitacion revocada"})
}

// ValidarInvitacion valida un token QR
// El kiosko llama este endpoint al escanear el QR para pre-llenar el formulario
//
// @Summary Validar token de invitación (kiosko)
// @Tags invitaciones
// @Produce json
// @Param token query string true "Token de la invitación"
// @Success 200 {object} ValidarInvitacionResponse
// @Failure 404 {object} map[string]string
// @Router /kioskos/{id}/invitaciones/validar [get]
func (h *Handler) ValidarInvitacion(c *gin.Context) {
	token := c.Query("token")
	if token == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "token requerido"})
		return
	}

	inv, err := h.repo.FindByToken(token)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "invitacion no valida, expirada o agotada"})
		return
	}

	c.JSON(http.StatusOK, toValidarResponse(inv))
}

// UsarInvitacion valida el token, crea un registro de Visita APROBADO y registra el uso
//
// @Summary Usar invitación (kiosko)
// @Tags invitaciones
// @Produce json
// @Param token path string true "Token de la invitación"
// @Success 200 {object} map[string]interface{}
// @Failure 404 {object} map[string]string
// @Router /kioskos/{id}/invitaciones/{token}/usar [post]
func (h *Handler) UsarInvitacion(c *gin.Context) {
	token := c.Param("token")

	kioskoIDStr := c.Param("id")
	kioskoID, err := strconv.ParseUint(kioskoIDStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "kiosko id invalido"})
		return
	}

	inv, err := h.repo.FindByToken(token)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "invitacion no valida, expirada o agotada"})
		return
	}

	var casaDestino string
	h.db.Table("destinos").Select("nombre").Where("id = ?", inv.DestinoID).Scan(&casaDestino)

	v := &visitas.Visita{
		Titular:       inv.Titular,
		TipoVisitante: visitas.TipoConInvitacion,
		TipoDocumento: visitas.DocumentoQR,
		MotivoVisita:  "Invitación QR",
		CasaDestino:   casaDestino,
		Estado:        visitas.EstadoAprobado,
		KioskoID:      uint(kioskoID),
	}
	if err := h.db.Create(v).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error registrando visita"})
		return
	}

	if err := h.repo.IncrementarUso(inv.ID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"titular":      inv.Titular,
		"casa_destino": casaDestino,
	})
}
