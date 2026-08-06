package tenant

import "time"

// CreateTenantRequest define el payload para registrar un nuevo fraccionamiento
type CreateTenantRequest struct {
	Nombre    string `json:"nombre" binding:"required"`
	Direccion string `json:"direccion"`
}

// TenantResponse es la representación segura que se devuelve al cliente
type TenantResponse struct {
	ID        uint      `json:"id"`
	Nombre    string    `json:"nombre"`
	Direccion string    `json:"direccion"`
	CreatedAt time.Time `json:"created_at"`
}
