package persona

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strconv"
	"strings"
	"time"

	"kigo-autonomia-backend/internal/platform/ctxkeys"
	"kigo-autonomia-backend/internal/platform/sse"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// AsistenciaUrgenteHandler atiende el botón de "llamar al vigilante" del
// kiosko -- no es un menú de FAQ, es un aviso directo de que un visitante
// necesita ayuda humana YA. Avisa por dos canales redundantes: SSE al
// dashboard (para quien lo tenga abierto en ese momento) y correo a los
// admins del tenant (para cuando no) -- y además queda persistida (ver
// asistencia_urgente_model.go) para que el dashboard tenga un listado real
// en vez de depender de agarrar el toast de 5 segundos al vuelo.
type AsistenciaUrgenteHandler struct {
	repo           *Repository
	asistenciaRepo *AsistenciaUrgenteRepository
	mailer         EmailSender
	hub            *sse.Hub
}

func NewAsistenciaUrgenteHandler(repo *Repository, asistenciaRepo *AsistenciaUrgenteRepository, mailer EmailSender, hub *sse.Hub) *AsistenciaUrgenteHandler {
	return &AsistenciaUrgenteHandler{repo: repo, asistenciaRepo: asistenciaRepo, mailer: mailer, hub: hub}
}

// asistenciaUrgenteEvento lleva "tipo" para que el dashboard lo distinga de
// un VisitaResponse normal en el mismo stream SSE, y "tenant_id" para que
// el cliente descarte eventos de otros tenants -- el Hub es global y hace
// broadcast a todos los admins conectados sin filtrar por tenant. "id" es
// el de la fila persistida, para que el dashboard pueda hacer deep-link al
// listado en vez de solo mostrar un toast que no lleva a ningún lado.
type asistenciaUrgenteEvento struct {
	Tipo      string    `json:"tipo"`
	ID        uint      `json:"id"`
	TenantID  uint      `json:"tenant_id"`
	KioskoID  uint      `json:"kiosko_id"`
	Motivo    string    `json:"motivo"`
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

	// El body es opcional a propósito: el kiosko de antes de este cambio
	// manda el POST sin body ni Content-Type, y debe seguir funcionando --
	// un ShouldBindJSON que falla aquí no debe tumbar la solicitud.
	var body struct {
		Motivo string `json:"motivo"`
	}
	_ = c.ShouldBindJSON(&body)
	motivo := strings.TrimSpace(body.Motivo)

	asistencia := &AsistenciaUrgente{TenantID: tenantID, KioskoID: kioskoID, Motivo: motivo}
	if err := h.asistenciaRepo.Crear(asistencia); err != nil {
		log.Printf("AsistenciaUrgenteHandler: error guardando solicitud: %v", err)
		// Aun si falla el registro, el aviso en vivo (SSE/correo) sigue
		// siendo mejor que nada -- no se corta la función aquí.
	}

	if h.hub != nil {
		evento := asistenciaUrgenteEvento{
			Tipo: "asistencia_urgente", ID: asistencia.ID, TenantID: tenantID,
			KioskoID: kioskoID, Motivo: motivo, CreatedAt: time.Now(),
		}
		if data, err := json.Marshal(evento); err == nil {
			h.hub.Broadcast(data)
		}
	}

	go h.avisarAdmin(tenantID, kioskoID, motivo)

	c.JSON(http.StatusOK, gin.H{"message": "asistencia solicitada"})
}

func (h *AsistenciaUrgenteHandler) avisarAdmin(tenantID, kioskoID uint, motivo string) {
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
	if motivo != "" {
		cuerpo += fmt.Sprintf("\n\nMotivo: %s", motivo)
	}
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

// asistenciaUrgenteResponse es el DTO de listado para el dashboard admin.
type asistenciaUrgenteResponse struct {
	ID           uint       `json:"id"`
	KioskoID     uint       `json:"kiosko_id"`
	KioskoNombre string     `json:"kiosko_nombre"`
	Motivo       string     `json:"motivo"`
	Estado       string     `json:"estado"`
	CreatedAt    time.Time  `json:"created_at"`
	ResueltaAt   *time.Time `json:"resuelta_at,omitempty"`
}

// ListarAsistencias devuelve las solicitudes del tenant del admin logueado,
// más recientes primero -- ?estado=pendiente filtra solo las no atendidas
// (para el badge/listado por defecto del dashboard).
//
// @Summary Listar asistencias urgentes
// @Tags asistencia-urgente
// @Produce json
// @Param estado query string false "pendiente para filtrar solo las no atendidas"
// @Success 200 {object} map[string]any
// @Router /asistencias-urgentes [get]
func (h *AsistenciaUrgenteHandler) ListarAsistencias(c *gin.Context) {
	tenantID := c.MustGet(ctxkeys.TenantID).(uint)
	soloPendientes := c.Query("estado") == AsistenciaUrgenteEstadoPendiente

	list, err := h.asistenciaRepo.ListarPorTenant(tenantID, soloPendientes)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	items := make([]asistenciaUrgenteResponse, 0, len(list))
	for _, a := range list {
		items = append(items, asistenciaUrgenteResponse{
			ID: a.ID, KioskoID: a.KioskoID, KioskoNombre: a.KioskoNombre,
			Motivo: a.Motivo, Estado: a.Estado, CreatedAt: a.CreatedAt, ResueltaAt: a.ResueltaAt,
		})
	}
	c.JSON(http.StatusOK, gin.H{"asistencias": items, "total": len(items)})
}

// MarcarResuelta marca una solicitud como atendida por el admin logueado.
//
// @Summary Marcar asistencia urgente como resuelta
// @Tags asistencia-urgente
// @Produce json
// @Param id path int true "ID de la solicitud"
// @Success 200 {object} map[string]string
// @Router /asistencias-urgentes/{id}/resolver [patch]
func (h *AsistenciaUrgenteHandler) MarcarResuelta(c *gin.Context) {
	id64, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID inválido"})
		return
	}
	tenantID := c.MustGet(ctxkeys.TenantID).(uint)
	adminID := c.MustGet(ctxkeys.AdminID).(uint)

	if err := h.asistenciaRepo.MarcarResuelta(uint(id64), tenantID, adminID); err != nil {
		if err == gorm.ErrRecordNotFound {
			c.JSON(http.StatusNotFound, gin.H{"error": "asistencia no encontrada"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"estado": AsistenciaUrgenteEstadoResuelta})
}
