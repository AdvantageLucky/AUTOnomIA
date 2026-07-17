package destinos

import "time"

// DestinoKioskoResponse DTO que devuelve el kiosko: incluye titular para verificación de IA,
// aunque el kiosko no lo muestre directamente en pantalla.
type DestinoKioskoResponse struct {
	ID       uint      `json:"id"`
	Nombre   string    `json:"nombre"`
	Titular  string    `json:"titular"`
	AccesoID uint      `json:"acceso_id"`
	CreatedAt time.Time `json:"created_at"`
}

// DestinoAdminRequest DTO para crear/editar un destino desde el dashboard
type DestinoAdminRequest struct {
	Nombre  string `json:"nombre"  binding:"required"`
	Titular string `json:"titular" binding:"required"`
}

func toDestinoKioskoResponse(d Destino) DestinoKioskoResponse {
	return DestinoKioskoResponse{
		ID:        d.ID,
		Nombre:    d.Nombre,
		Titular:   d.Titular,
		AccesoID:  d.AccesoID,
		CreatedAt: d.CreatedAt,
	}
}
