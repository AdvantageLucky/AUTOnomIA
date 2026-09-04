package seguridad

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strconv"
	"strings"
	"time"

	"kigo-autonomia-backend/internal/domain/residente"
	"kigo-autonomia-backend/internal/domain/visitas"
	"kigo-autonomia-backend/internal/platform/ctxkeys"
	"kigo-autonomia-backend/internal/platform/sse"

	"github.com/gin-gonic/gin"
)

// umbralCorrelacionPct es el mismo 85% por defecto que
// kiosko_configs.umbral_similitud_cara (ver migración 000076): no vale la
// pena traer aquí el repo de KioskoConfig solo para leer un valor que casi
// nunca se cambia por kiosko -- correlacionar intentos fallidos es una señal
// para el admin, no una decisión de acceso, así que un umbral fijo razonable
// basta.
const umbralCorrelacionPct = 85

type Handler struct {
	repo       *Repository
	uploadsDir string
	mailer     EmailSender
	hub        *sse.Hub
}

func NewHandler(repo *Repository, uploadsDir string, mailer EmailSender, hub *sse.Hub) *Handler {
	return &Handler{repo: repo, uploadsDir: uploadsDir, mailer: mailer, hub: hub}
}

// eventoSeguridadEvento es lo que viaja por SSE al dashboard -- mismo
// patrón que asistenciaUrgenteEvento en persona/asistencia_urgente_handler.go.
type eventoSeguridadEvento struct {
	Tipo       string    `json:"tipo"`
	ID         uint      `json:"id"`
	TenantID   uint      `json:"tenant_id"`
	KioskoID   uint      `json:"kiosko_id"`
	EventoTipo string    `json:"evento_tipo"`
	CreatedAt  time.Time `json:"created_at"`
}

// Reportar registra un intento de acceso fallido (PIN incorrecto, QR
// inválido) desde un kiosko autenticado por su propia sesión, con foto
// opcional del intento.
//
// @Summary Reportar evento de seguridad
// @Tags seguridad
// @Produce json
// @Param id path int true "ID del kiosko"
// @Success 200 {object} map[string]string
// @Router /kioskos/{id}/eventos-seguridad [post]
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

	tipo := strings.TrimSpace(c.PostForm("tipo"))
	if tipo != TipoPinIncorrecto && tipo != TipoQrInvalido {
		c.JSON(http.StatusBadRequest, gin.H{"error": "tipo debe ser 'pin_incorrecto' o 'qr_invalido'"})
		return
	}
	detalle := strings.TrimSpace(c.PostForm("detalle"))

	var fotoURL string
	if fh, err := c.FormFile("foto"); err == nil && fh != nil {
		url, err := visitas.GuardarFotoVisitante(c, fh, h.uploadsDir)
		if err != nil {
			log.Printf("EventoSeguridad: error guardando foto: %v", err)
		} else {
			fotoURL = url
		}
	}

	// El embedding viaja como JSON de floats en un campo de texto normal
	// (no un archivo) -- mismo campo/formato que ya usa el kiosko para
	// visitas (ver KioskoServicio._enviarRegistro, 'embedding_rostro').
	repo := h.repo.WithContext(c.Request.Context())
	var embedding residente.FloatArray
	var intentosPrevios int
	if raw := c.PostForm("embedding_rostro"); raw != "" {
		var vals []float64
		if err := json.Unmarshal([]byte(raw), &vals); err != nil {
			log.Printf("EventoSeguridad: embedding_rostro invalido: %v", err)
		} else {
			embedding = residente.FloatArray(vals)
			if n, err := repo.ContarCorrelacionados(tenantID, vals, umbralCorrelacionPct); err != nil {
				log.Printf("EventoSeguridad: error correlacionando: %v", err)
			} else {
				intentosPrevios = n
			}
		}
	}

	evento := &EventoSeguridad{
		TenantID: tenantID, KioskoID: kioskoID, Tipo: tipo, Detalle: detalle, FotoURL: fotoURL,
		EmbeddingRostro: embedding, IntentosPrevios: intentosPrevios,
	}
	if err := repo.Crear(evento); err != nil {
		log.Printf("EventoSeguridad: error guardando: %v", err)
	}

	if h.hub != nil {
		sseEvento := eventoSeguridadEvento{
			Tipo: "evento_seguridad", ID: evento.ID, TenantID: tenantID,
			KioskoID: kioskoID, EventoTipo: tipo, CreatedAt: time.Now(),
		}
		if data, err := json.Marshal(sseEvento); err == nil {
			h.hub.Broadcast(data)
		}
	}

	go h.avisarAdmin(tenantID, kioskoID, tipo)

	c.JSON(http.StatusOK, gin.H{"message": "evento registrado"})
}

func (h *Handler) avisarAdmin(tenantID, kioskoID uint, tipo string) {
	if h.mailer == nil {
		return
	}
	correos, err := h.repo.CorreosAdminsDeTenant(tenantID)
	if err != nil {
		log.Printf("EventoSeguridad: error buscando admins del tenant %d: %v", tenantID, err)
		return
	}
	descripcion := "Intento de acceso con PIN incorrecto"
	if tipo == TipoQrInvalido {
		descripcion = "Intento de acceso con código QR inválido"
	}
	asunto := "Evento de seguridad en kiosko"
	cuerpo := fmt.Sprintf("%s en el kiosko #%d. Revisa el dashboard para ver la foto del intento.", descripcion, kioskoID)
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	for _, correo := range correos {
		if correo == "" {
			continue
		}
		if err := h.mailer.Enviar(ctx, correo, asunto, cuerpo); err != nil {
			log.Printf("EventoSeguridad: error mandando correo a %s: %v", correo, err)
		}
	}
}

type eventoSeguridadResponse struct {
	ID              uint      `json:"id"`
	KioskoID        uint      `json:"kiosko_id"`
	KioskoNombre    string    `json:"kiosko_nombre"`
	Tipo            string    `json:"tipo"`
	Detalle         string    `json:"detalle"`
	FotoURL         string    `json:"foto_url"`
	CreatedAt       time.Time `json:"created_at"`
	// IntentosPrevios > 0 significa que este mismo rostro ya generó otros
	// eventos de seguridad antes en este tenant (ver ContarCorrelacionados).
	IntentosPrevios int `json:"intentos_previos"`
}

// Listar devuelve los eventos de seguridad del tenant del admin logueado,
// más recientes primero -- ?tipo= filtra por tipo.
//
// @Summary Listar eventos de seguridad
// @Tags seguridad
// @Produce json
// @Param tipo query string false "pin_incorrecto o qr_invalido"
// @Success 200 {object} map[string]any
// @Router /eventos-seguridad [get]
func (h *Handler) Listar(c *gin.Context) {
	tenantID := c.MustGet(ctxkeys.TenantID).(uint)
	tipo := c.Query("tipo")

	list, err := h.repo.WithContext(c.Request.Context()).ListarPorTenant(tenantID, tipo)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	items := make([]eventoSeguridadResponse, 0, len(list))
	for _, e := range list {
		items = append(items, eventoSeguridadResponse{
			ID: e.ID, KioskoID: e.KioskoID, KioskoNombre: e.KioskoNombre, Tipo: e.Tipo,
			Detalle: e.Detalle, FotoURL: e.FotoURL, CreatedAt: e.CreatedAt,
			IntentosPrevios: e.IntentosPrevios,
		})
	}
	c.JSON(http.StatusOK, gin.H{"eventos": items, "total": len(items)})
}
