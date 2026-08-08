package residente

import "time"

type LoginResidenteRequest struct {
	KioskoID    uint   `json:"kiosko_id"    binding:"required"`
	CasaDestino string `json:"casa_destino" binding:"required"`
	Pin         string `json:"pin"          binding:"required,min=4,max=6"`
}

type CrearResidenteRequest struct {
	Nombre          string `json:"nombre"           binding:"required"`
	ApellidoPaterno string `json:"apellido_paterno" binding:"required"`
	ApellidoMaterno string `json:"apellido_materno" binding:"required"`
	Pin             string `json:"pin"              binding:"required,min=4,max=6"`
	CasaDestino     string `json:"casa_destino"     binding:"required"`
	Telefono        string `json:"telefono"`
	KioskoID        uint   `json:"kiosko_id"        binding:"required"`
}

type ResidenteResponse struct {
	ID              uint      `json:"id"`
	Nombre          string    `json:"nombre"`
	ApellidoPaterno string    `json:"apellido_paterno"`
	ApellidoMaterno string    `json:"apellido_materno"`
	CasaDestino     string    `json:"casa_destino"`
	Telefono        string    `json:"telefono"`
	KioskoID        *uint     `json:"kiosko_id"`
	DestinoID       *uint     `json:"destino_id"`
	Status          string    `json:"status"`
	FotoCaraUrl     string    `json:"foto_cara_url,omitempty"`
	CreatedAt       time.Time `json:"created_at"`
}

func toResidenteResponse(r Residente, destinoID *uint) ResidenteResponse {
	return ResidenteResponse{
		ID:              r.ID,
		Nombre:          r.Nombre,
		ApellidoPaterno: r.ApellidoPaterno,
		ApellidoMaterno: r.ApellidoMaterno,
		CasaDestino:     r.CasaDestino,
		Telefono:        r.Telefono,
		KioskoID:        r.KioskoID,
		DestinoID:       destinoID,
		Status:          r.Status,
		FotoCaraUrl:     r.FotoCaraUrl,
		CreatedAt:       r.CreatedAt,
	}
}
