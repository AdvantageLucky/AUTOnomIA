/*
Package admin

DTOs relacionados a dominio admin (cuenta de admin)
Representan respuestas o peticiones relacionadas con el modelo Admin
Usado en endpoints para recibir una respuesta o enviar una respuesta con un cuerpo en especifico
*/
package admin

// AdminRequest DTO para modificar un Admin
type AdminRequest struct {
	Nombre          string `json:"nombre"`
	ApellidoPaterno string `json:"apellido_paterno"`
	ApellidoMaterno string `json:"apellido_materno"`
	Correo          string `json:"correo"           binding:"omitempty,email"`
	Password        string `json:"password"         binding:"omitempty,min=6"`
}

// AdminResponse DTO para devolver info de un Admin, nunca incluye Password
type AdminResponse struct {
	ID              uint   `json:"id"`
	Nombre          string `json:"nombre"`
	ApellidoPaterno string `json:"apellido_paterno"`
	ApellidoMaterno string `json:"apellido_materno"`
	Correo          string `json:"correo"`
}

// helper func para convertir un Admin (DB Model) a DTO Response
func toAdminResponse(a *Admin) AdminResponse {
	return AdminResponse{
		ID:              a.ID,
		Nombre:          a.Nombre,
		ApellidoPaterno: a.ApellidoPaterno,
		ApellidoMaterno: a.ApellidoMaterno,
		Correo:          a.Correo,
	}
}
