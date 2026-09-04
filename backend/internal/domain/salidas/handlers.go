package salidas

import (
	"log"
	"net/http"
	"strconv"
	"time"

	"kigo-autonomia-backend/internal/domain/visitas"
	"kigo-autonomia-backend/internal/platform/ctxkeys"

	"github.com/gin-gonic/gin"
)

type Handler struct {
	repo       *Repository
	uploadsDir string
}

func NewHandler(repo *Repository, uploadsDir string) *Handler {
	return &Handler{repo: repo, uploadsDir: uploadsDir}
}

// Reportar registra una salida: tap + foto de rostro, desde un kiosko de
// salida autenticado por su propia sesión. Foto opcional por el mismo
// criterio que seguridad.Handler.Reportar -- mejor un registro sin foto que
// ningún registro.
//
// @Summary Registrar una salida
// @Tags salidas
// @Produce json
// @Param id path int true "ID del kiosko"
// @Success 200 {object} map[string]string
// @Router /kioskos/{id}/salidas [post]
func (h *Handler) Reportar(c *gin.Context) {
	kioskoID64, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID de kiosko inválido"})
		return
	}
	kioskoID := uint(kioskoID64)

	sesionKioskoID := c.MustGet(ctxkeys.KioskoID).(uint)
	if sesionKioskoID != kioskoID {
		c.JSON(http.StatusForbidden, gin.H{"error": "la sesion no corresponde a este kiosko"})
		return
	}
	tenantID := c.MustGet(ctxkeys.TenantID).(uint)

	var fotoURL string
	if fh, err := c.FormFile("foto"); err == nil && fh != nil {
		url, err := visitas.GuardarFotoVisitante(c, fh, h.uploadsDir)
		if err != nil {
			log.Printf("Salida: error guardando foto: %v", err)
		} else {
			fotoURL = url
		}
	}

	salida := &Salida{TenantID: tenantID, KioskoID: kioskoID, FotoURL: fotoURL}
	if err := h.repo.Crear(salida); err != nil {
		log.Printf("Salida: error guardando: %v", err)
	}

	c.JSON(http.StatusOK, gin.H{"message": "salida registrada"})
}

type salidaResponse struct {
	ID           uint      `json:"id"`
	KioskoID     uint      `json:"kiosko_id"`
	KioskoNombre string    `json:"kiosko_nombre"`
	FotoURL      string    `json:"foto_url"`
	CreatedAt    time.Time `json:"created_at"`
}

// Listar (admin) devuelve la bitácora de salidas del tenant, más recientes
// primero.
//
// @Summary Listar salidas
// @Tags salidas
// @Produce json
// @Success 200 {object} map[string]any
// @Router /salidas [get]
func (h *Handler) Listar(c *gin.Context) {
	tenantID := c.MustGet(ctxkeys.TenantID).(uint)

	list, err := h.repo.ListarPorTenant(tenantID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	items := make([]salidaResponse, 0, len(list))
	for _, s := range list {
		items = append(items, salidaResponse{
			ID: s.ID, KioskoID: s.KioskoID, KioskoNombre: s.KioskoNombre,
			FotoURL: s.FotoURL, CreatedAt: s.CreatedAt,
		})
	}
	c.JSON(http.StatusOK, gin.H{"salidas": items, "total": len(items)})
}
