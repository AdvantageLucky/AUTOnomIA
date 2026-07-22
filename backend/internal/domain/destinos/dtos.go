/*
Package destinos

DTOs relacionados a el dominio destinos
Representan respuestas o peticiones relacionados con el modelo Destino
Usado en endpoints para recibir una respuesta o enviar una respuesta con un cuerpo en especifico
*/
package destinos

import "time"

// DestinoKioskoResponse DTO para listar destinos a los cuales quiera ir una Visita sin Invitacion
// tiene informacion del titular del posible destino, etc
type DestinoKioskoResponse struct {
	ID        uint      `json:"id"`
	Nombre    string    `json:"nombre"`
	Titular   string    `json:"titular"`
	KioskoID  uint   `json:"kiosko_id"`
	CreatedAt time.Time `json:"created_at"`
}

// DestinoAdminRequest DTO para crear/editar un destino desde el dashboard
type DestinoAdminRequest struct {
	Nombre  string `json:"nombre"  binding:"required"`
	Titular string `json:"titular" binding:"required"`
}

// helper func para convertir un Destinos (DB Model) a DTO Response
func toDestinoKioskoResponse(d Destino) DestinoKioskoResponse {
	return DestinoKioskoResponse{
		ID:        d.ID,
		Nombre:    d.Nombre,
		Titular:   d.Titular,
		KioskoID:  d.KioskoID,
		CreatedAt: d.CreatedAt,
	}
}
