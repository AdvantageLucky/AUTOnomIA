package destinos

import "time"

type DestinoKioskoResponse struct {
	ID        uint      `json:"id"`
	Nombre    string    `json:"nombre"`
	Titular   string    `json:"titular"`
	KioskoID  uint      `json:"kiosko_id"`
	CreatedAt time.Time `json:"created_at"`
}

type DestinoAdminRequest struct {
	Nombre  string `json:"nombre"  binding:"required"`
	Titular string `json:"titular" binding:"required"`
}

func toDestinoKioskoResponse(d Destino) DestinoKioskoResponse {
	return DestinoKioskoResponse{
		ID:        d.ID,
		Nombre:    d.Nombre,
		Titular:   d.Titular,
		KioskoID:  d.KioskoID,
		CreatedAt: d.CreatedAt,
	}
}
