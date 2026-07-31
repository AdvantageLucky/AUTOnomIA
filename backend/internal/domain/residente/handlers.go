package residente

import (
	"log"
	"net/http"
	"strconv"

	"kigo-autonomia-backend/internal/domain/auth"
	"kigo-autonomia-backend/internal/domain/visitas"
	"kigo-autonomia-backend/internal/platform/ctxkeys"

	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

// destinoFinder permite al handler de residente resolver el destino_id
// sin importar directamente el package destinos (evita acoplamiento).
type destinoFinder interface {
	FindByNombreAndKioskoID(nombre string, kioskoID uint) (uint, error)
}

type Handler struct {
	repo        *Repository
	destinoRepo destinoFinder
	jwtSecret   string
	db          *gorm.DB
}

func NewHandler(repo *Repository, destinoRepo destinoFinder, jwtSecret string, db *gorm.DB) *Handler {
	return &Handler{repo: repo, destinoRepo: destinoRepo, jwtSecret: jwtSecret, db: db}
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

// GetMe devuelve el perfil del residente autenticado, incluyendo destino_id si existe
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

	var destinoID *uint
	if h.destinoRepo != nil {
		if id, err := h.destinoRepo.FindByNombreAndKioskoID(res.CasaDestino, res.KioskoID); err == nil {
			destinoID = &id
		}
	}

	c.JSON(http.StatusOK, toResidenteResponse(*res, destinoID))
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

	c.JSON(http.StatusCreated, toResidenteResponse(*res, nil))
}

// LoginResidenteDesdeKiosko valida el PIN de un residente desde el kiosko autenticado.
// Protegido por RequireKiosko: el kiosko ya está autenticado con su sesión.
func (h *Handler) LoginResidenteDesdeKiosko(c *gin.Context) {
	kioskoIDStr := c.Param("id")
	kioskoID, err := strconv.ParseUint(kioskoIDStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID de kiosko invalido"})
		return
	}

	sesionKioskoID := c.MustGet(ctxkeys.KioskoID).(uint)
	if sesionKioskoID != uint(kioskoID) {
		c.JSON(http.StatusForbidden, gin.H{"error": "sesion no corresponde a este kiosko"})
		return
	}

	var req struct {
		Pin string `json:"pin" binding:"required,min=4,max=6"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	res, err := h.repo.FindPorPin(uint(kioskoID), req.Pin)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "PIN incorrecto"})
		return
	}

	v := &visitas.Visita{
		Titular:       res.Nombre + " " + res.ApellidoPaterno,
		TipoVisitante: visitas.TipoResidente,
		TipoDocumento: visitas.DocumentoPIN,
		MotivoVisita:  "Acceso por PIN",
		CasaDestino:   res.CasaDestino,
		Estado:        visitas.EstadoAprobado,
		KioskoID:      uint(kioskoID),
	}
	if err := h.db.Create(v).Error; err != nil {
		log.Printf("LoginResidenteDesdeKiosko: error registrando visita: %v", err)
	}

	c.JSON(http.StatusOK, gin.H{
		"nombre":       res.Nombre + " " + res.ApellidoPaterno,
		"casa_destino": res.CasaDestino,
	})
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
		items = append(items, toResidenteResponse(r, nil))
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
		items = append(items, toResidenteResponse(r, nil))
	}

	c.JSON(http.StatusOK, items)
}
