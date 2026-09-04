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
	ClientID      string                `form:"client_id"` // idempotencia: reenvios del kiosko tras sync offline
	FotoDocumento *multipart.FileHeader `form:"foto_documento"`
	FotoRostro    *multipart.FileHeader `form:"foto_rostro"`
	FotoPlaca     *multipart.FileHeader `form:"foto_placa"`
	// Nitidez de FotoDocumento, calculada en el kiosko (ver visitas.VisitaRequest).
	NitidezIneScore float64 `form:"nitidez_ine_score"`
	CalidadIne      string  `form:"calidad_ine"`
}

// CreateInvitacionRequest DTO para crear una invitacion desde la app del residente.
// El token lo genera el servidor
// MaxUsos nil = sin limite
// ExpiresAt nil = sin expiracion
type CreateInvitacionRequest struct {
	Tipo      TipoInvitacion `json:"tipo"       binding:"required,oneof=PERSONAL GRUPAL"`
	Titular   string         `json:"titular"    binding:"required"`
	DestinoID uint           `json:"destino_id" binding:"required"`
	Motivo    string         `json:"motivo"`
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
	Motivo     string         `json:"motivo,omitempty"`
	ConteoUsos int            `json:"conteo_usos"`
	MaxUsos    *int           `json:"max_usos"`
	ExpiresAt  *time.Time     `json:"expires_at"`
	RevokedAt  *time.Time     `json:"revoked_at,omitempty"`
	CreatedAt  time.Time      `json:"created_at"`
	// Telefono no vive en Invitacion (solo el enlace a la Persona invitada,
	// ver PersonaInvitadaID) -- lo rellena quien llama a ToInvitacionResponse
	// cuando le hace falta (ver ListarInvitaciones), no toInvitacionResponse
	// mismo, para no acoplar esta conversion a una consulta de Persona.
	Telefono string `json:"telefono,omitempty"`
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

// InvitacionRecibidaResponse DTO de respuesta para la Persona invitada —
// lo que ve en "invitaciones recibidas" dentro de kigo-app.
type InvitacionRecibidaResponse struct {
	ID           uint           `json:"id"`
	Tipo         TipoInvitacion `json:"tipo"`
	Titular      string         `json:"titular"`
	CasaDestino  string         `json:"casa_destino"`
	NombreInvita string         `json:"nombre_invita"`
	ExpiresAt    *time.Time     `json:"expires_at"`
	CreatedAt    time.Time      `json:"created_at"`
}

// ToInvitacionRecibidaResponse expone el mapeo a otros paquetes — el
// dominio persona arma la lista de invitaciones recibidas.
func ToInvitacionRecibidaResponse(inv *Invitacion, casaDestino, nombreInvita string) InvitacionRecibidaResponse {
	return InvitacionRecibidaResponse{
		ID:           inv.ID,
		Tipo:         inv.Tipo,
		Titular:      inv.Titular,
		CasaDestino:  casaDestino,
		NombreInvita: nombreInvita,
		ExpiresAt:    inv.ExpiresAt,
		CreatedAt:    inv.CreatedAt,
	}
}

// ToInvitacionResponse expone toInvitacionResponse a otros paquetes — el
// dominio persona necesita convertir una Invitacion a su DTO de respuesta
// sin duplicar el mapeo.
func ToInvitacionResponse(inv *Invitacion, incluirToken bool) InvitacionResponse {
	return toInvitacionResponse(inv, incluirToken)
}

// helper func para convertir una Invitacion (DB Model) a DTO Response
func toInvitacionResponse(inv *Invitacion, incluirToken bool) InvitacionResponse {
	r := InvitacionResponse{
		ID:         inv.ID,
		Tipo:       inv.Tipo,
		Titular:    inv.Titular,
		DestinoID:  inv.DestinoID,
		Motivo:     inv.Motivo,
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
