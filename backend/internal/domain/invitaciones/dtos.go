/*
Package invitaciones
DTOs del dominio invitaciones

CreateInvitacionRequest — lo manda la app del residente y el token lo genera el servidor
InvitacionResponse — respuesta al residente, el token solo aparece en la creación
ValidarInvitacionResponse — respuesta al kiosko, incluye datos para pre-llenar la visita
*/
package invitaciones

import (
	"mime/multipart"
	"time"
)

// UsarInvitacionRequest DTO opcional que el kiosko manda como multipart/form-data
// al consumir una invitacion.
//
// Todos los campos son opcionales: un kiosko peatonal sin capturas configuradas
// sigue mandando un POST sin cuerpo, como antes. Un kiosko vehicular con
// foto_placa_invitado encendido manda aqui la placa y su foto, que es la unica
// forma de que esa config se cumpla para un invitado (ver ADR-0023).
type UsarInvitacionRequest struct {
	Curp          string                `form:"curp"`
	Placa         string                `form:"placa"`
	FotoDocumento *multipart.FileHeader `form:"foto_documento"`
	FotoRostro    *multipart.FileHeader `form:"foto_rostro"`
	FotoPlaca     *multipart.FileHeader `form:"foto_placa"`
}

// CreateInvitacionRequest DTO para crear una invitacion desde la app del residente.
// El token lo genera el servidor
// MaxUsos nil = sin limite
// ExpiresAt nil = sin expiracion
type CreateInvitacionRequest struct {
	Tipo      TipoInvitacion `json:"tipo"       binding:"required,oneof=PERSONAL GRUPAL"`
	Titular   string         `json:"titular"    binding:"required"`
	DestinoID uint           `json:"destino_id" binding:"required"`
	MaxUsos   *int           `json:"max_usos"`
	ExpiresAt *time.Time     `json:"expires_at"`
}

// InvitacionResponse DTO de respuesta para el residente
// Token solo viaja en la respuesta de creacion
type InvitacionResponse struct {
	ID         uint           `json:"id"`
	Token      string         `json:"token,omitempty"`
	Tipo       TipoInvitacion `json:"tipo"`
	Titular    string         `json:"titular"`
	DestinoID  uint           `json:"destino_id"`
	ConteoUsos int            `json:"conteo_usos"`
	MaxUsos    *int           `json:"max_usos"`
	ExpiresAt  *time.Time     `json:"expires_at"`
	RevokedAt  *time.Time     `json:"revoked_at,omitempty"`
	CreatedAt  time.Time      `json:"created_at"`
}

// ValidarInvitacionResponse DTO de respuesta que el kiosko recibe al validar un token
// Incluye los datos necesarios para pre-llenar el formulario de registro de visita
type ValidarInvitacionResponse struct {
	ID          uint           `json:"id"`
	Tipo        TipoInvitacion `json:"tipo"`
	Titular     string         `json:"titular"`
	DestinoID   uint           `json:"destino_id"`
	CasaDestino string         `json:"casa_destino"`
	ConteoUsos  int            `json:"conteo_usos"`
	MaxUsos     *int           `json:"max_usos"`
	ExpiresAt   *time.Time     `json:"expires_at"`
}

// helper func para convertir una Invitacion (DB Model) a DTO Response
func toInvitacionResponse(inv *Invitacion, incluirToken bool) InvitacionResponse {
	r := InvitacionResponse{
		ID:         inv.ID,
		Tipo:       inv.Tipo,
		Titular:    inv.Titular,
		DestinoID:  inv.DestinoID,
		ConteoUsos: inv.ConteoUsos,
		MaxUsos:    inv.MaxUsos,
		ExpiresAt:  inv.ExpiresAt,
		CreatedAt:  inv.CreatedAt,
	}
	if incluirToken {
		r.Token = inv.Token
	}
	if inv.DeletedAt.Valid {
		t := inv.DeletedAt.Time
		r.RevokedAt = &t
	}
	return r
}

// helper func para convertir una Invitacion (DB Model) a DTO ValidarResponse
// casaDestino se resuelve en el handler porque vive en la tabla destinos
func toValidarResponse(inv *Invitacion, casaDestino string) ValidarInvitacionResponse {
	return ValidarInvitacionResponse{
		ID:          inv.ID,
		Tipo:        inv.Tipo,
		Titular:     inv.Titular,
		DestinoID:   inv.DestinoID,
		CasaDestino: casaDestino,
		ConteoUsos:  inv.ConteoUsos,
		MaxUsos:     inv.MaxUsos,
		ExpiresAt:   inv.ExpiresAt,
	}
}
