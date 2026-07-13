/*
Package acceso

Paquete de estructuras que representan respuestas o peticiones relacionados con el modelo Acceso
Usado en endpoints para recibir una respuesta o enviar una respuesta con un cuerpo en especifico
*/
package acceso

// AccesoRequest DTO para dar de alta o modificar un acceso
type AccesoRequest struct {
	Nombre    string `json:"nombre"    binding:"required"`
	Ubicacion string `json:"ubicacion"`
}

// AccesoResponse DTO para devolver info de un acceso despues de ser creado/modificado
// ClaveKiosko solo viaja en la respuesta de RegisterAccess (texto plano, una sola vez); en cualquier
// otra respuesta queda vacio y se omite del JSON, porque el servidor solo guarda su hash bcrypt
type AccesoResponse struct {
	ID          uint   `json:"id"`
	Nombre      string `json:"nombre"`
	Ubicacion   string `json:"ubicacion"`
	AdminID     uint   `json:"usuario_id"`
	ClaveKiosko string `json:"clave_kiosko,omitempty"`
}
