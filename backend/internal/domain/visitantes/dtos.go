/*
Package visitantes

Paquete de estructuras que representan respuestas o peticiones relacionadas con el modelo Visitante
Usado en endpoints para recibir una respuesta o enviar una respuesta con un cuerpo en especifico
*/
package visitantes

import (
	"mime/multipart"
	"time"
)

// VisitanteRequest DTO para dar de alta un Visitante de un Acceso. Va como multipart/form-data
// (no JSON) porque incluye dos archivos: la foto del documento (INE/pasaporte/licencia) y la foto
// de la cara de la persona. El kiosko las sube en la misma llamada, el servidor las guarda en
// disco y genera las URLs, el cliente nunca las manda
// AccesoID no va aqui porque se toma del URL param :id de /accesos/:id/visitantes
type VisitanteRequest struct {
	Nombre        string                `form:"nombre"         binding:"required"`
	TipoDocumento TipoDocumento         `form:"tipo_documento" binding:"required,oneof=INE PASAPORTE LICENCIA"`
	ClaveLector   string                `form:"clave_lector"   binding:"required"`
	Curp          string                `form:"curp"           binding:"required,len=18"`
	FotoDocumento *multipart.FileHeader `form:"foto_documento" binding:"required"`
	FotoRostro    *multipart.FileHeader `form:"foto_rostro"    binding:"required"`
}

// VisitanteResponse DTO para devolver info de un Visitante
type VisitanteResponse struct {
	ID               uint          `json:"id"`
	Nombre           string        `json:"nombre"`
	TipoDocumento    TipoDocumento `json:"tipo_documento"`
	ClaveLector      string        `json:"clave_lector"`
	Curp             string        `json:"curp"`
	FotoDocumentoURL string        `json:"foto_documento_url"`
	FotoRostroURL    string        `json:"foto_rostro_url"`
	AccesoID         uint          `json:"acceso_id"`
	CreatedAt        time.Time     `json:"created_at"`
}

// VisitanteListItemResponse DTO reducido para el listado de visitantes (dashboard): omite CURP y
// ClaveLector a proposito (son los dos datos mas sensibles); para verlos hay que entrar al detalle
// de una entrada especifica via GET /visitantes/{id}
type VisitanteListItemResponse struct {
	ID            uint          `json:"id"`
	Nombre        string        `json:"nombre"`
	TipoDocumento TipoDocumento `json:"tipo_documento"`
	AccesoID      uint          `json:"acceso_id"`
	CreatedAt     time.Time     `json:"created_at"`
}

// VisitantesPaginadosResponse DTO para el listado paginado de visitantes de un admin (dashboard)
type VisitantesPaginadosResponse struct {
	Visitantes []VisitanteListItemResponse `json:"visitantes"`
	Total      int64                       `json:"total"`
	Page       int                         `json:"page"`
	PageSize   int                         `json:"page_size"`
}

// HistorialVisitanteResponse DTO para el historial de visitas de una persona por su CURP (dashboard)
type HistorialVisitanteResponse struct {
	Curp         string              `json:"curp"`
	TotalVisitas int                 `json:"total_visitas"`
	Visitas      []VisitanteResponse `json:"visitas"`
}
