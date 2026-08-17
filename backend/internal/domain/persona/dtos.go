package persona

import (
	"time"

	"kigo-autonomia-backend/internal/domain/invitaciones"
)

type SolicitarOtpRequest struct {
	Telefono string `json:"telefono" binding:"required"`
}

type VerificarOtpRequest struct {
	Telefono        string    `json:"telefono" binding:"required"`
	Codigo          string    `json:"codigo"   binding:"required,len=6"`
	Nombre          string    `json:"nombre"`
	ApellidoPaterno string    `json:"apellido_paterno"`
	ApellidoMaterno string    `json:"apellido_materno"`
	Embedding       []float64 `json:"embedding"`
}

type QrResponse struct {
	PersonaID uint   `json:"persona_id"`
	Firma     string `json:"firma"`
}

type UnirseCentroRequest struct {
	CodigoCentro string `json:"codigo_centro" binding:"required"`
	CasaDestino  string `json:"casa_destino"  binding:"required"`
	Pin          string `json:"pin"           binding:"required,min=4,max=6"`
}

type MembresiaResponse struct {
	ID          uint   `json:"id"`
	TenantID    uint   `json:"tenant_id"`
	CasaDestino string `json:"casa_destino"`
	Rol         string `json:"rol"`
	Status      string `json:"status"`
}

type CrearInvitacionPersonaRequest struct {
	TenantID                    uint                        `json:"tenant_id"        binding:"required"`
	TelefonoInvitado            string                      `json:"telefono_invitado" binding:"required"`
	Tipo                        invitaciones.TipoInvitacion `json:"tipo"             binding:"required,oneof=PERSONAL GRUPAL"`
	DestinoID                   uint                        `json:"destino_id"       binding:"required"`
	PermiteReconocimientoFacial bool                        `json:"permite_reconocimiento_facial"`
	MaxUsos                     *int                        `json:"max_usos"`
	ExpiresAt                   *time.Time                  `json:"expires_at"`
}
