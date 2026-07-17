package visitas

import (
	"mime/multipart"
	"time"
)

// VisitaRequest DTO para registrar una visita desde el kiosko. Va como multipart/form-data
// porque incluye las fotos del documento y del rostro.
// AccesoID no va aqui: se toma del URL param :id de /accesos/:id/visitas
type VisitaRequest struct {
	Nombre        string                `form:"nombre"         binding:"required"`
	TipoDocumento TipoDocumento         `form:"tipo_documento" binding:"required,oneof=INE PASAPORTE LICENCIA"`
	ClaveLector   string                `form:"clave_lector"   binding:"required"`
	Curp          string                `form:"curp"           binding:"required,len=18"`
	MotivoVisita  string                `form:"motivo_visita"  binding:"required"`
	CasaDestino   string                `form:"casa_destino"   binding:"required"`
	Placa         string                `form:"placa"`
	FotoDocumento *multipart.FileHeader `form:"foto_documento" binding:"required"`
	FotoRostro    *multipart.FileHeader `form:"foto_rostro"    binding:"required"`
}

// VisitaResponse DTO de respuesta completo para una visita
type VisitaResponse struct {
	ID               uint          `json:"id"`
	Nombre           string        `json:"nombre"`
	TipoDocumento    TipoDocumento `json:"tipo_documento"`
	ClaveLector      string        `json:"clave_lector"`
	Curp             string        `json:"curp"`
	FotoDocumentoURL string        `json:"foto_documento_url"`
	FotoRostroURL    string        `json:"foto_rostro_url"`
	MotivoVisita     string        `json:"motivo_visita"`
	CasaDestino      string        `json:"casa_destino"`
	Placa            string        `json:"placa"`
	Estado           EstadoVisita  `json:"estado"`
	AccesoID         uint          `json:"acceso_id"`
	CreatedAt        time.Time     `json:"created_at"`
}

// VisitaListItemResponse DTO reducido para el listado del dashboard: omite CURP y clave_lector
type VisitaListItemResponse struct {
	ID            uint          `json:"id"`
	Nombre        string        `json:"nombre"`
	TipoDocumento TipoDocumento `json:"tipo_documento"`
	CasaDestino   string        `json:"casa_destino"`
	MotivoVisita  string        `json:"motivo_visita"`
	Estado        EstadoVisita  `json:"estado"`
	AccesoID      uint          `json:"acceso_id"`
	CreatedAt     time.Time     `json:"created_at"`
}

// VisitasPaginadasResponse DTO para el listado paginado
type VisitasPaginadasResponse struct {
	Visitas  []VisitaListItemResponse `json:"visitas"`
	Total    int64                    `json:"total"`
	Page     int                      `json:"page"`
	PageSize int                      `json:"page_size"`
}

// HistorialVisitaResponse DTO para historial por CURP
type HistorialVisitaResponse struct {
	Curp         string           `json:"curp"`
	TotalVisitas int              `json:"total_visitas"`
	Visitas      []VisitaResponse `json:"visitas"`
}

func toVisitaResponse(v Visita) VisitaResponse {
	return VisitaResponse{
		ID:               v.ID,
		Nombre:           v.Nombre,
		TipoDocumento:    v.TipoDocumento,
		ClaveLector:      v.ClaveLector,
		Curp:             v.Curp,
		FotoDocumentoURL: v.FotoDocumentoURL,
		FotoRostroURL:    v.FotoRostroURL,
		MotivoVisita:     v.MotivoVisita,
		CasaDestino:      v.CasaDestino,
		Placa:            v.Placa,
		Estado:           v.Estado,
		AccesoID:         v.AccesoID,
		CreatedAt:        v.CreatedAt,
	}
}

func toVisitaListItemResponse(v Visita) VisitaListItemResponse {
	return VisitaListItemResponse{
		ID:            v.ID,
		Nombre:        v.Nombre,
		TipoDocumento: v.TipoDocumento,
		CasaDestino:   v.CasaDestino,
		MotivoVisita:  v.MotivoVisita,
		Estado:        v.Estado,
		AccesoID:      v.AccesoID,
		CreatedAt:     v.CreatedAt,
	}
}
