package sync

import (
	"net/http"
	"strconv"

	"kigo-autonomia-backend/internal/domain/destinos"
	"kigo-autonomia-backend/internal/domain/invitaciones"
	"kigo-autonomia-backend/internal/domain/persona"
	"kigo-autonomia-backend/internal/domain/residente"
	"kigo-autonomia-backend/internal/platform/ctxkeys"

	"github.com/gin-gonic/gin"
)

type Handler struct {
	destinoRepo    *destinos.Repository
	personaRepo    *persona.Repository
	invitacionRepo *invitaciones.Repository
}

func NewHandler(destinoRepo *destinos.Repository, personaRepo *persona.Repository, invitacionRepo *invitaciones.Repository) *Handler {
	return &Handler{destinoRepo: destinoRepo, personaRepo: personaRepo, invitacionRepo: invitacionRepo}
}

// GetSnapshot arma en una sola respuesta todo lo que el kiosko necesita
// cachear para operar sin red: destinos, residentes con huella facial, e
// invitaciones activas. Solo ensambla queries que ya existen en cada
// dominio — sin logica de negocio nueva.
func (h *Handler) GetSnapshot(c *gin.Context) {
	kioskoIDStr := c.Param("id")
	kioskoID, err := strconv.ParseUint(kioskoIDStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID de kiosko invalido"})
		return
	}
	sesionKioskoID := c.MustGet(ctxkeys.KioskoID).(uint)
	if sesionKioskoID != uint(kioskoID) {
		c.JSON(http.StatusForbidden, gin.H{"error": "la sesion no corresponde a este kiosko"})
		return
	}
	tenantID := c.MustGet(ctxkeys.TenantID).(uint)

	destinosList, err := h.destinoRepo.WithContext(c.Request.Context()).FindByTenantID(tenantID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	residentesList, err := h.personaRepo.FindActivasPorTenant(tenantID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	invitacionesList, err := h.invitacionRepo.FindActivasNoExpiradasByTenant(tenantID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	destinoNombrePorID := make(map[uint]string, len(destinosList))
	for _, d := range destinosList {
		destinoNombrePorID[d.ID] = d.Nombre
	}

	resp := SnapshotResponse{
		Destinos:     make([]DestinoSnapshot, 0, len(destinosList)),
		Residentes:   make([]ResidenteSnapshot, 0, len(residentesList)),
		Invitaciones: make([]InvitacionSnapshot, 0, len(invitacionesList)),
	}
	for _, d := range destinosList {
		resp.Destinos = append(resp.Destinos, DestinoSnapshot{
			ID: d.ID, Calle: d.Calle, Tipo: string(d.Tipo), Numero: d.Numero, Nombre: d.Nombre,
		})
	}
	for _, r := range residentesList {
		emb := r.Embedding
		if emb == nil {
			emb = []float64{}
		}
		resp.Residentes = append(resp.Residentes, ResidenteSnapshot{
			ID: r.MembresiaID, PersonaID: r.PersonaID, Nombre: r.Nombre, ApellidoPaterno: r.ApellidoPaterno,
			CasaDestino: r.CasaDestino, PinHash: r.PinHash, Embedding: emb,
			EsInvitadoFrecuente: r.Rol == residente.RolInvitadoFrecuente,
		})
	}
	for _, inv := range invitacionesList {
		var expiresAt *string
		if inv.ExpiresAt != nil {
			s := inv.ExpiresAt.Format("2006-01-02T15:04:05Z07:00")
			expiresAt = &s
		}
		resp.Invitaciones = append(resp.Invitaciones, InvitacionSnapshot{
			Token: inv.Token, Titular: inv.Titular,
			CasaDestino: destinoNombrePorID[inv.DestinoID], ExpiresAt: expiresAt,
			PersonaInvitadaID: inv.PersonaInvitadaID, PermiteReconocimientoFacial: inv.PermiteReconocimientoFacial,
		})
	}

	c.JSON(http.StatusOK, resp)
}
