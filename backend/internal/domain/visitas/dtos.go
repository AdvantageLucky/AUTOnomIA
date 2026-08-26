/*
Package visitas

DTOs relacionados al dominio visitas
Representan peticiones y respuestas de los endpoints de visitas
*/
package visitas

import (
	"mime/multipart"
	"time"
)

// VisitaRequest DTO para registrar una visita desde el kiosko
// Dependiendo las configuraciones del kiosko se pediran mas o menos documentos
// como por ejemplo foto de rostro + foto de placa.
//
// Caso visitante sin invitacion
// para poder garantizar busquedas de personas por sus visitas se requiere por lo menos
// que se scanee la ine y se manden sus archivo
//
// Caso visitante con invitacion
// Cuando el residente genera la invitacion esta ya tiene titular, tipo de docu
// por lo que se puede garantizar busquedas
// Titular y TipoDocumento no llevan `required` en el binding porque un acceso
// vehicular sin INE no tiene ni nombre ni documento que ofrecer; su obligatoriedad
// se decide en ValidarCamposCondicionales segun el tipo de kiosko (ADR-0016 §4).
type VisitaRequest struct {
	Titular       string                `form:"titular"`
	TipoVisitante TipoVisitante         `form:"tipo_visitante" binding:"required,oneof=VISITANTE INVITADO"`
	TipoDocumento TipoDocumento         `form:"tipo_documento" binding:"omitempty,oneof=INE PASAPORTE LICENCIA QR PLACA"`
	Curp          string                `form:"curp"`
	CasaDestino   string                `form:"casa_destino"   binding:"required"`
	Placa         string                `form:"placa"`
	ClientID      string                `form:"client_id"` // idempotencia: reenvios del kiosko tras sync offline
	FotoDocumento *multipart.FileHeader `form:"foto_documento"` // Content-Type image
	FotoRostro    *multipart.FileHeader `form:"foto_rostro"`    // Content-Type image
	FotoPlaca     *multipart.FileHeader `form:"foto_placa"`     // Content-Type image
}

// VisitaResponse DTO de respuesta completo para una visita
type VisitaResponse struct {
	ID                  uint          `json:"id"`
	Titular             string        `json:"titular"`
	TipoDocumento       TipoDocumento `json:"tipo_documento"`
	TipoVisitante       TipoVisitante `json:"tipo_visitante"`
	Curp                string        `json:"curp"`
	FotoDocumentoURL    string        `json:"foto_documento_url"`
	FotoRostroURL       string        `json:"foto_rostro_url"`
	FotoPlacaURL        string        `json:"foto_placa_url,omitempty"`
	CasaDestino         string        `json:"casa_destino"`
	Placa               string        `json:"placa"`
	Estado              EstadoVisita  `json:"estado"`
	Intervenida         bool          `json:"intervenida"`
	KioskoID            uint          `json:"kiosko_id"`
	AutorizadoPorTipo   string        `json:"autorizado_por_tipo,omitempty"`
	AutorizadoPorNombre string        `json:"autorizado_por_nombre,omitempty"`
	CreatedAt           time.Time     `json:"created_at"`
}

// VisitaListItemResponse DTO reducido para el listado del dashboard (omite CURP y clave_lector)
type VisitaListItemResponse struct {
	ID                  uint          `json:"id"`
	Titular             string        `json:"titular"`
	TipoDocumento       TipoDocumento `json:"tipo_documento"`
	TipoVisitante       TipoVisitante `json:"tipo_visitante"`
	CasaDestino         string        `json:"casa_destino"`
	Estado              EstadoVisita  `json:"estado"`
	Intervenida         bool          `json:"intervenida"`
	KioskoID            uint          `json:"kiosko_id"`
	AutorizadoPorTipo   string        `json:"autorizado_por_tipo,omitempty"`
	AutorizadoPorNombre string        `json:"autorizado_por_nombre,omitempty"`
	CreatedAt           time.Time     `json:"created_at"`
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

// ToVisitaResponse expone toVisitaResponse a otros dominios (p. ej. residente,
// para responder los endpoints de aprobar/rechazar y listar pendientes).
func ToVisitaResponse(v Visita) VisitaResponse {
	return toVisitaResponse(v)
}

// helper func para convertir una Visita (DB Model) a DTO Response
func toVisitaResponse(v Visita) VisitaResponse {
	return VisitaResponse{
		ID:                  v.ID,
		Titular:             v.Titular,
		TipoDocumento:       v.TipoDocumento,
		TipoVisitante:       v.TipoVisitante,
		Curp:                v.Curp,
		FotoDocumentoURL:    v.FotoDocumentoURL,
		FotoRostroURL:       v.FotoRostroURL,
		FotoPlacaURL:        v.FotoPlacaURL,
		CasaDestino:         v.CasaDestino,
		Placa:               v.Placa,
		Estado:              v.Estado,
		Intervenida:         v.Intervenida,
		KioskoID:            v.KioskoID,
		AutorizadoPorTipo:   v.AutorizadoPorTipo,
		AutorizadoPorNombre: v.AutorizadoPorNombre,
		CreatedAt:           v.CreatedAt,
	}
}

// helper func para convertir una Visita (DB Model) a DTO VisitaListItemResponse
// pensado para iterar visitas y retornar []VisitaListItemResponse
func toVisitaListItemResponse(v Visita) VisitaListItemResponse {
	return VisitaListItemResponse{
		ID:                  v.ID,
		Titular:             v.Titular,
		TipoVisitante:       v.TipoVisitante,
		TipoDocumento:       v.TipoDocumento,
		CasaDestino:         v.CasaDestino,
		Estado:              v.Estado,
		Intervenida:         v.Intervenida,
		KioskoID:            v.KioskoID,
		AutorizadoPorTipo:   v.AutorizadoPorTipo,
		AutorizadoPorNombre: v.AutorizadoPorNombre,
		CreatedAt:           v.CreatedAt,
	}
}
