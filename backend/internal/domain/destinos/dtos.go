package destinos

import "time"

type DestinoResponse struct {
	ID        uint      `json:"id"`
	Nombre    string    `json:"nombre"`
	Titular   string    `json:"titular"`
	CreatedAt time.Time `json:"created_at"`
}

// DestinoKioskoResponse mantenido por compatibilidad con la app kiosko
type DestinoKioskoResponse = DestinoResponse

type DestinoAdminRequest struct {
	Nombre  string `json:"nombre"  binding:"required"`
	Titular string `json:"titular" binding:"required"`
}

func toDestinoResponse(d Destino) DestinoResponse {
	return DestinoResponse{
		ID:        d.ID,
		Nombre:    d.Nombre,
		Titular:   d.Titular,
		CreatedAt: d.CreatedAt,
	}
}

// toDestinoKioskoResponse mantenido por compatibilidad
var toDestinoKioskoResponse = toDestinoResponse
