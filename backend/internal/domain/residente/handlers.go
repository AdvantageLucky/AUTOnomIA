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

func (h *Handler) LoginResidente(c *gin.Context) {
	var req LoginResidenteRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "campos incorrectos"})
		return
	}

	repoCtx := h.repo.WithContext(c.Request.Context())

	res, err := repoCtx.FindByCasaAndKiosko(req.CasaDestino, req.KioskoID)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "residente no encontrado"})
		return
	}

	if err := bcrypt.CompareHashAndPassword([]byte(res.Pin), []byte(req.Pin)); err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "pin incorrecto"})
		return
	}

	token, err := auth.GenerateResidenteToken(res.ID, res.TenantID, h.jwtSecret)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, auth.JWTResponse{AccessToken: token})
}

func (h *Handler) GetMe(c *gin.Context) {
	residenteID := c.MustGet(ctxkeys.ResidenteID).(uint)

	repoCtx := h.repo.WithContext(c.Request.Context())

	res, err := repoCtx.FindByID(residenteID)
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

func (h *Handler) CrearResidente(c *gin.Context) {
	adminID := c.MustGet(ctxkeys.AdminID).(uint)
	tenantID := c.MustGet(ctxkeys.TenantID).(uint)

	var req CrearResidenteRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	repoCtx := h.repo.WithContext(c.Request.Context())

	if err := repoCtx.VerificarOwnershipKiosko(req.KioskoID, adminID); err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "kiosko no encontrado"})
		return
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(req.Pin), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	res := &Residente{
		TenantID:        tenantID,
		Nombre:          req.Nombre,
		ApellidoPaterno: req.ApellidoPaterno,
		ApellidoMaterno: req.ApellidoMaterno,
		Pin:             string(hash),
		CasaDestino:     req.CasaDestino,
		Telefono:        req.Telefono,
		KioskoID:        req.KioskoID,
	}

	if err := repoCtx.Create(res); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, toResidenteResponse(*res, nil))
}

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

	repoCtx := h.repo.WithContext(c.Request.Context())

	res, err := repoCtx.FindPorPin(uint(kioskoID), req.Pin)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "PIN incorrecto"})
		return
	}

	v := &visitas.Visita{
		TenantID:      res.TenantID,
		Titular:       res.Nombre + " " + res.ApellidoPaterno,
		TipoVisitante: visitas.TipoResidente,
		TipoDocumento: visitas.DocumentoPIN,
		MotivoVisita:  "Acceso por PIN",
		CasaDestino:   res.CasaDestino,
		Estado:        visitas.EstadoAprobado,
		KioskoID:      uint(kioskoID),
	}

	// Acoplamos también el contexto en la db de visitas al crearla
	if err := h.db.WithContext(c.Request.Context()).Create(v).Error; err != nil {
		log.Printf("LoginResidenteDesdeKiosko: error registrando visita: %v", err)
	}

	c.JSON(http.StatusOK, gin.H{
		"nombre":       res.Nombre + " " + res.ApellidoPaterno,
		"casa_destino": res.CasaDestino,
	})
}

func (h *Handler) ListarResidentesPorAcceso(c *gin.Context) {
	adminID := c.MustGet(ctxkeys.AdminID).(uint)

	kioskoIDStr := c.Param("id")
	kioskoID, err := strconv.ParseUint(kioskoIDStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID invalido"})
		return
	}

	repoCtx := h.repo.WithContext(c.Request.Context())

	if err := repoCtx.VerificarOwnershipKiosko(uint(kioskoID), adminID); err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "kiosko no encontrado"})
		return
	}

	list, err := repoCtx.FindByKioskoID(uint(kioskoID))
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

func (h *Handler) ListarResidentesAdmin(c *gin.Context) {
	adminID := c.MustGet(ctxkeys.AdminID).(uint)

	repoCtx := h.repo.WithContext(c.Request.Context())

	list, err := repoCtx.FindAllByAdminID(adminID)
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
