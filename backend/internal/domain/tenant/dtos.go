package tenant

import "time"

type UpdateTenantRequest struct {
	Nombre           string `json:"nombre"`
	Direccion        string `json:"direccion"`
	Descripcion      string `json:"descripcion"`
	TelefonoContacto string `json:"telefono_contacto"`
}

type TenantResponse struct {
	ID          uint      `json:"id"`
	Nombre      string    `json:"nombre"`
	Direccion   string    `json:"direccion"`
	Codigo      string    `json:"codigo"`
	Descripcion string    `json:"descripcion"`
	// Número del vigilante/admin que muestra el botón "hablar con el
	// administrador" en el kiosko -- funciona incluso sin internet en el
	// kiosko porque el visitante marca desde su propio celular (red móvil).
	// Un solo número por centro, no uno por kiosko (ver ADR pendiente /
	// migración 000071).
	TelefonoContacto string    `json:"telefono_contacto"`
	CreatedAt        time.Time `json:"created_at"`
}
