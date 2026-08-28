package persona

import (
	"net/http"
	"strconv"

	"kigo-autonomia-backend/internal/domain/visitas"
	"kigo-autonomia-backend/internal/platform/ctxkeys"

	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

// KioskoLoginHandler reemplaza a residente.Handler.LoginResidenteDesdeKiosko/
// VerificarRostroDesdeKiosko — mismo contrato de request/response, pero
// busca en Persona+Membresia en vez de Residente (ver spec 2026-08-26).
// Separado de persona.Handler a propósito: no necesita OTP, QR ni
// invitaciones, solo el repo y la db para crear la Visita.
type KioskoLoginHandler struct {
	repo       *Repository
	visitaRepo *visitas.Repository
	db         *gorm.DB
}

func NewKioskoLoginHandler(repo *Repository, visitaRepo *visitas.Repository, db *gorm.DB) *KioskoLoginHandler {
	return &KioskoLoginHandler{repo: repo, visitaRepo: visitaRepo, db: db}
}

func (h *KioskoLoginHandler) umbralSimilitud(kioskoID uint) float64 {
	const umbralPorDefecto = 0.70
	var umbral float64
	row := h.db.Table("kiosko_configs").
		Select("umbral_similitud_cara").
		Where("kiosko_id = ?", kioskoID).
		Row()
	if err := row.Scan(&umbral); err != nil {
		return umbralPorDefecto
	}
	return umbral
}

func (h *KioskoLoginHandler) LoginDesdeKiosko(c *gin.Context) {
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

	tenantID := c.MustGet(ctxkeys.TenantID).(uint)

	var req struct {
		Pin       string `json:"pin" binding:"required,min=4,max=6"`
		PersonaID *uint  `json:"persona_id"`
		ClientID  string `json:"client_id"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	candidatos, err := h.repo.FindActivasPorTenant(tenantID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	var matches []CandidatoKiosko
	for i := range candidatos {
		if candidatos[i].PinHash != "" && bcrypt.CompareHashAndPassword([]byte(candidatos[i].PinHash), []byte(req.Pin)) == nil {
			matches = append(matches, candidatos[i])
		}
	}
	if len(matches) == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "PIN incorrecto"})
		return
	}

	var mejor *CandidatoKiosko
	if len(matches) == 1 {
		mejor = &matches[0]
	} else if req.PersonaID != nil {
		for i := range matches {
			if matches[i].PersonaID == *req.PersonaID {
				mejor = &matches[i]
				break
			}
		}
		if mejor == nil {
			mejor = &matches[0]
		}
	} else {
		candidatosList := make([]gin.H, 0, len(matches))
		for _, m := range matches {
			candidatosList = append(candidatosList, gin.H{
				"persona_id":   m.PersonaID,
				"nombre":       m.Nombre + " " + m.ApellidoPaterno,
				"casa_destino": m.CasaDestino,
			})
		}
		c.JSON(http.StatusOK, gin.H{
			"requiere_seleccion": true,
			"candidatos":         candidatosList,
		})
		return
	}

	var clientIDPtr *string
	if req.ClientID != "" {
		clientIDPtr = &req.ClientID
		repoCtx := h.visitaRepo.WithContext(c.Request.Context())
		existente, err := repoCtx.FindByClientID(tenantID, req.ClientID)
		if err == nil && existente != nil {
			c.JSON(http.StatusOK, gin.H{
				"nombre":       mejor.Nombre + " " + mejor.ApellidoPaterno,
				"casa_destino": mejor.CasaDestino,
			})
			return
		}
	}

	v := &visitas.Visita{
		TenantID:      tenantID,
		Titular:       mejor.Nombre + " " + mejor.ApellidoPaterno,
		TipoVisitante: visitas.TipoResidente,
		TipoDocumento: visitas.DocumentoPIN,
		CasaDestino:   mejor.CasaDestino,
		Estado:        visitas.EstadoAprobado,
		KioskoID:      uint(kioskoID),
		PersonaID:     &mejor.PersonaID,
		ClientID:      clientIDPtr,
	}
	if err := h.db.WithContext(c.Request.Context()).Create(v).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error registrando visita"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"nombre":       mejor.Nombre + " " + mejor.ApellidoPaterno,
		"casa_destino": mejor.CasaDestino,
	})
}

func (h *KioskoLoginHandler) VerificarRostroDesdeKiosko(c *gin.Context) {
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

	tenantID := c.MustGet(ctxkeys.TenantID).(uint)

	var req struct {
		Embedding []float64 `json:"embedding" binding:"required"`
		ClientID  string    `json:"client_id"`
	}
	if err := c.ShouldBindJSON(&req); err != nil || len(req.Embedding) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "embedding inválido"})
		return
	}

	if req.ClientID != "" {
		existente, err := h.visitaRepo.WithContext(c.Request.Context()).FindByClientID(tenantID, req.ClientID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		if existente != nil {
			c.JSON(http.StatusOK, gin.H{
				"nombre":       existente.Titular,
				"casa_destino": existente.CasaDestino,
			})
			return
		}
	}

	candidatos, err := h.repo.FindActivasPorTenant(tenantID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	mejor, score := mejorCandidatoRostro(candidatos, req.Embedding)
	if mejor == nil || score < h.umbralSimilitud(uint(kioskoID)) {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "rostro no reconocido"})
		return
	}

	v := &visitas.Visita{
		TenantID:      tenantID,
		Titular:       mejor.Nombre + " " + mejor.ApellidoPaterno,
		TipoVisitante: visitas.TipoResidente,
		TipoDocumento: visitas.DocumentoRostro,
		CasaDestino:   mejor.CasaDestino,
		Estado:        visitas.EstadoAprobado,
		KioskoID:      uint(kioskoID),
		ClientID:      visitas.ClientIDPtr(req.ClientID),
		PersonaID:     &mejor.PersonaID,
	}
	if err := h.db.WithContext(c.Request.Context()).Create(v).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error registrando visita"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"nombre":       mejor.Nombre + " " + mejor.ApellidoPaterno,
		"casa_destino": mejor.CasaDestino,
	})
}
