package persona

import (
	"time"

	"kigo-autonomia-backend/internal/domain/invitaciones"
)

type SolicitarOtpRequest struct {
	Telefono string `json:"telefono" binding:"required"`
	// Correo es opcional — si viene, el código se manda por correo en vez
	// de SMS. El teléfono sigue siendo el ancla de identidad; esto solo
	// cambia el canal de entrega del código mientras no haya un proveedor
	// de SMS real configurado.
	Correo string `json:"correo"`
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

// UnirseCentroRequest ya no lleva PIN: lo genera el backend (5 dígitos) al
// crear la membresía y se lo devuelve a la app para que lo muestre.
type UnirseCentroRequest struct {
	CodigoCentro string `json:"codigo_centro" binding:"required"`
	CasaDestino  string `json:"casa_destino"  binding:"required"`
}

type MembresiaResponse struct {
	ID          uint   `json:"id"`
	TenantID    uint   `json:"tenant_id"`
	CasaDestino string `json:"casa_destino"`
	Status      string `json:"status"`
	Pin         string `json:"pin"`
}

type VerificarQRRequest struct {
	PersonaID uint      `json:"persona_id" binding:"required"`
	Firma     string    `json:"firma"      binding:"required"`
	Embedding []float64 `json:"embedding"`
}

type VerificarQRResponse struct {
	Estado                      EstadoQR `json:"estado"`
	Nombre                      string   `json:"nombre"`
	CasaDestino                 string   `json:"casa_destino,omitempty"`
	DestinoID                   *uint    `json:"destino_id,omitempty"`
	PermiteReconocimientoFacial bool     `json:"permite_reconocimiento_facial"`
	InvitacionID                *uint    `json:"invitacion_id,omitempty"`
	VisitaID                    *uint    `json:"visita_id,omitempty"`
}

type CrearInvitacionPersonaRequest struct {
	TenantID                    uint                        `json:"tenant_id"        binding:"required"`
	TelefonoInvitado            string                      `json:"telefono_invitado" binding:"required"`
	NombreInvitado              string                      `json:"nombre_invitado"`
	Tipo                        invitaciones.TipoInvitacion `json:"tipo"             binding:"required,oneof=PERSONAL GRUPAL"`
	DestinoID                   uint                        `json:"destino_id"       binding:"required"`
	PermiteReconocimientoFacial bool                        `json:"permite_reconocimiento_facial"`
	MaxUsos                     *int                        `json:"max_usos"`
	ExpiresAt                   *time.Time                  `json:"expires_at"`
}

type PersonaMeResponse struct {
	Telefono             string     `json:"telefono"`
	Nombre               string     `json:"nombre"`
	ApellidoPaterno      string     `json:"apellido_paterno"`
	ApellidoMaterno      string     `json:"apellido_materno"`
	TelefonoVerificadoAt *time.Time `json:"telefono_verificado_at"`
	Curp                 string     `json:"curp"`
	FotoIneUrl           string     `json:"foto_ine_url"`
}

func toPersonaMeResponse(p *Persona) PersonaMeResponse {
	return PersonaMeResponse{
		Telefono:             p.Telefono,
		Nombre:               p.Nombre,
		ApellidoPaterno:      p.ApellidoPaterno,
		ApellidoMaterno:      p.ApellidoMaterno,
		TelefonoVerificadoAt: p.TelefonoVerificadoAt,
		Curp:                 p.Curp,
		FotoIneUrl:           p.FotoIneUrl,
	}
}

type DeviceTokenRequest struct {
	DeviceToken string `json:"device_token" binding:"required"`
}

type PatchPersonaMeRequest struct {
	Nombre          string `json:"nombre"`
	ApellidoPaterno string `json:"apellido_paterno"`
	ApellidoMaterno string `json:"apellido_materno"`
}

type ResponderVisitaPersonaRequest struct {
	Estado string `json:"estado" binding:"required"`
}

type MembresiaMeResponse struct {
	ID           uint   `json:"id"`
	TenantID     uint   `json:"tenant_id"`
	CentroNombre string `json:"centro_nombre"`
	CasaDestino  string `json:"casa_destino"`
	Status       string `json:"status"`
	// Pin son los 5 dígitos en claro — la app los muestra en "Mi QR". Va
	// solo en esta respuesta, que ya está autenticada como la Persona
	// dueña de la membresía.
	Pin string `json:"pin"`
}
