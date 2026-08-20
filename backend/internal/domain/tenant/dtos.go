package tenant

import "time"

type UpdateTenantRequest struct {
	Nombre      string `json:"nombre"`
	Direccion   string `json:"direccion"`
	Descripcion string `json:"descripcion"`
}

type TenantResponse struct {
	ID          uint      `json:"id"`
	Nombre      string    `json:"nombre"`
	Direccion   string    `json:"direccion"`
	Codigo      string    `json:"codigo"`
	Descripcion string    `json:"descripcion"`
	CreatedAt   time.Time `json:"created_at"`
}
