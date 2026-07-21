/*
Package residente

DTOs relacionados a el dominio residente
Representan respuestas o peticiones relacionados con el modelo Residente
Usado en endpoints para recibir una respuesta o enviar una respuesta con un cuerpo en especifico
*/
package residente

import "time"

// ResidenteResponse DTO para retornar informacion actual de residente
type ResidenteResponse struct {
	ID              uint      `json:"id"`
	Nombre          string    `json:"nombre"`
	ApellidoPaterno string    `json:"apellido_paterno"`
	ApellidoMaterno string    `json:"apellido_materno"`
	CasaDestino     string    `json:"casa_destino"`
	Telefono        string    `json:"telefono"`
	AccesoID        uint      `json:"acceso_id"`
	CreatedAt       time.Time `json:"created_at"`
}

// LoginResidenteRequest login del residente con AccesoID + CasaDestino + PIN
type LoginResidenteRequest struct {
	AccesoID    uint   `json:"acceso_id"    binding:"required"`
	CasaDestino string `json:"casa_destino" binding:"required"`
	Pin         string `json:"pin"          binding:"required,min=4,max=6"`
}

// CrearResidenteRequest para que el admin cree un residente desde el dashboard
type CrearResidenteRequest struct {
	Nombre          string `json:"nombre"           binding:"required"`
	ApellidoPaterno string `json:"apellido_paterno" binding:"required"`
	ApellidoMaterno string `json:"apellido_materno" binding:"required"`
	Pin             string `json:"pin"              binding:"required,min=4,max=6"`
	CasaDestino     string `json:"casa_destino"     binding:"required"`
	Telefono        string `json:"telefono"`
	AccesoID        uint   `json:"acceso_id"        binding:"required"`
}

// helper func para convertir un Residente (DB Model) a DTO Response
func toResidenteResponse(r Residente) ResidenteResponse {
	return ResidenteResponse{
		ID:              r.ID,
		Nombre:          r.Nombre,
		ApellidoPaterno: r.ApellidoPaterno,
		ApellidoMaterno: r.ApellidoMaterno,
		CasaDestino:     r.CasaDestino,
		Telefono:        r.Telefono,
		AccesoID:        r.AccesoID,
		CreatedAt:       r.CreatedAt,
	}
}
