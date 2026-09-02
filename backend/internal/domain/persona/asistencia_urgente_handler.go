package persona

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strconv"
	"time"

	"kigo-autonomia-backend/internal/platform/ctxkeys"
	"kigo-autonomia-backend/internal/platform/sse"

	"github.com/gin-gonic/gin"
)

// AsistenciaUrgenteHandler atiende el botón de "llamar al vigilante" del
// kiosko -- no es un menú de FAQ, es un aviso directo de que un visitante
// necesita ayuda humana YA. Avisa por dos canales redundantes: SSE al
// dashboard (para quien lo tenga abierto en ese momento) y correo a los
// admins del tenant (para cuando no).
type AsistenciaUrgenteHandler struct {
	repo   *Repository
	mailer EmailSender
	hub    *sse.Hub
}

func NewAsistenciaUrgenteHandler(repo *Repository, mailer EmailSender, hub *sse.Hub) *AsistenciaUrgenteHandler {
	return &AsistenciaUrgenteHandler{repo: repo, mailer: mailer, hub: hub}
}

// asistenciaUrgenteEvento lleva "tipo" para que el dashboard lo distinga de
// un VisitaResponse normal en el mismo stream SSE, y "tenant_id" para que
// el cliente descarte eventos de otros tenants -- el Hub es global y hace
// broadcast a todos los admins conectados sin filtrar por tenant.
type asistenciaUrgenteEvento struct {
	Tipo      string    `json:"tipo"`
	TenantID  uint      `json:"tenant_id"`
	KioskoID  uint      `json:"kiosko_id"`
	CreatedAt time.Time `json:"created_at"`
}

// Solicitar registra una petición de asistencia urgente desde un kiosko
// autenticado por su propia sesión.
//
// @Summary Solicitar asistencia urgente
// @Description El visitante pide ayuda humana ya -- avisa al admin por SSE y correo
// @Tags persona
// @Produce json
// @Param id path int true "ID del kiosko"
// @Success 200 {object} map[string]string
// @Router /kioskos/{id}/asistencia-urgente [post]
func (h *AsistenciaUrgenteHandler) Solicitar(c *gin.Context) {
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

	if h.hub != nil {
		evento := asistenciaUrgenteEvento{
			Tipo: "asistencia_urgente", TenantID: tenantID, KioskoID: kioskoID, CreatedAt: time.Now(),
		}
		if data, err := json.Marshal(evento); err == nil {
			h.hub.Broadcast(data)
		}
	}

	go h.avisarAdmin(tenantID, kioskoID)

	c.JSON(http.StatusOK, gin.H{"message": "asistencia solicitada"})
}

func (h *AsistenciaUrgenteHandler) avisarAdmin(tenantID, kioskoID uint) {
	if h.mailer == nil {
		return
	}
	correos, err := h.repo.CorreosAdminsDeTenant(tenantID)
	if err != nil {
		log.Printf("AsistenciaUrgenteHandler: error buscando admins del tenant %d: %v", tenantID, err)
		return
	}
	asunto := "Asistencia urgente solicitada en kiosko"
	cuerpo := fmt.Sprintf("Un visitante pidió ayuda urgente en el kiosko #%d. Revisa el dashboard o acude en persona.", kioskoID)
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	for _, correo := range correos {
		if correo == "" {
			continue
		}
		if err := h.mailer.Enviar(ctx, correo, asunto, cuerpo); err != nil {
			log.Printf("AsistenciaUrgenteHandler: error mandando correo a %s: %v", correo, err)
		}
	}
}
