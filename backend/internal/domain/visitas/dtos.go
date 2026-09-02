/*
Package visitas

DTOs relacionados al dominio visitas
Representan peticiones y respuestas de los endpoints de visitas
*/
package visitas

import (
	"encoding/json"
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
	Titular       string        `form:"titular"`
	TipoVisitante TipoVisitante `form:"tipo_visitante" binding:"required,oneof=VISITANTE INVITADO"`
	TipoDocumento TipoDocumento `form:"tipo_documento" binding:"omitempty,oneof=INE PASAPORTE LICENCIA QR PLACA"`
	Curp          string        `form:"curp"`
	Motivo        string        `form:"motivo"`
	CasaDestino   string        `form:"casa_destino"   binding:"required"`
	Placa         string        `form:"placa"`
	ClientID      string        `form:"client_id"` // idempotencia: reenvios del kiosko tras sync offline
	// EmbeddingRostro viaja como JSON ("[0.1,0.2,...]") en un campo de texto
	// del multipart: el binding de formularios no arma un slice de floats
	// desde un solo campo. Opcional — un kiosko viejo simplemente no lo manda.
	EmbeddingRostro string                `form:"embedding_rostro"`
	FotoDocumento   *multipart.FileHeader `form:"foto_documento"` // Content-Type image
	FotoRostro      *multipart.FileHeader `form:"foto_rostro"`    // Content-Type image
	FotoPlaca       *multipart.FileHeader `form:"foto_placa"`     // Content-Type image
	// Nitidez de FotoDocumento, calculada en el kiosko (EvidenciaCalidadServicio).
	// Ninguno de los dos es obligatorio: solo aplica cuando hay foto de INE.
	NitidezIneScore float64 `form:"nitidez_ine_score"`
	CalidadIne      string  `form:"calidad_ine"`
}

// VisitaResponse DTO de respuesta completo para una visita
type VisitaResponse struct {
	ID                  uint                 `json:"id"`
	Titular             string               `json:"titular"`
	TipoDocumento       TipoDocumento        `json:"tipo_documento"`
	TipoVisitante       TipoVisitante        `json:"tipo_visitante"`
	Curp                string               `json:"curp"`
	FotoDocumentoURL    string               `json:"foto_documento_url"`
	NitidezIneScore     float64              `json:"nitidez_ine_score"`
	CalidadIne          string               `json:"calidad_ine,omitempty"`
	FotoRostroURL       string               `json:"foto_rostro_url"`
	FotoPlacaURL        string               `json:"foto_placa_url,omitempty"`
	CasaDestino         string               `json:"casa_destino"`
	Motivo              string               `json:"motivo,omitempty"`
	Placa               string               `json:"placa"`
	Estado              EstadoVisita         `json:"estado"`
	Intervenida         bool                 `json:"intervenida"`
	KioskoID            uint                 `json:"kiosko_id"`
	AutorizadoPorTipo   string               `json:"autorizado_por_tipo,omitempty"`
	AutorizadoPorNombre string               `json:"autorizado_por_nombre,omitempty"`
	AutorizadoPorCorreo string               `json:"autorizado_por_correo,omitempty"`
	AutorizadoPorRol    string               `json:"autorizado_por_rol,omitempty"`
	CreatedAt           time.Time            `json:"created_at"`
	ResumenIA           *string              `json:"resumen_ia,omitempty"`
	ScoreIA             *ScoreIA             `json:"score_ia,omitempty"`
	Estadisticas        *EstadisticasPersona `json:"estadisticas,omitempty"`
	// Telefono nunca lo llena este paquete -- v.PersonaID no dice por sí
	// solo si esa Persona ya verificó su teléfono (cuenta real de Kigo) o
	// es solo un registro "en blanco" de una invitación nunca reclamada.
	// Lo rellena el dominio persona, que sí tiene esa distinción a la mano
	// (ver ListarVisitasPendientes/ListarHistorialVisitas).
	Telefono string `json:"telefono,omitempty"`
	// PersonaCurp es la CURP del perfil de la Persona vinculada (si la
	// dio al enrolarse), NO la capturada en esta entrada -- se muestra
	// aparte para no mezclar "lo que se leyó ahora" con "lo que ya
	// sabíamos de antes". Solo aplica a TipoResidente.
	PersonaCurp string `json:"persona_curp,omitempty"`
}

// VisitaListItemResponse DTO reducido para el listado del dashboard (omite CURP y clave_lector)
type VisitaListItemResponse struct {
	ID                  uint                 `json:"id"`
	Titular             string               `json:"titular"`
	TipoDocumento       TipoDocumento        `json:"tipo_documento"`
	TipoVisitante       TipoVisitante        `json:"tipo_visitante"`
	CasaDestino         string               `json:"casa_destino"`
	Motivo              string               `json:"motivo,omitempty"`
	Estado              EstadoVisita         `json:"estado"`
	Intervenida         bool                 `json:"intervenida"`
	KioskoID            uint                 `json:"kiosko_id"`
	AutorizadoPorTipo   string               `json:"autorizado_por_tipo,omitempty"`
	AutorizadoPorNombre string               `json:"autorizado_por_nombre,omitempty"`
	AutorizadoPorCorreo string               `json:"autorizado_por_correo,omitempty"`
	AutorizadoPorRol    string               `json:"autorizado_por_rol,omitempty"`
	CreatedAt           time.Time            `json:"created_at"`
	ResumenIA           *string              `json:"resumen_ia,omitempty"`
	ScoreIA             *ScoreIA             `json:"score_ia,omitempty"`
	Estadisticas        *EstadisticasPersona `json:"estadisticas,omitempty"`
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
	resp := VisitaResponse{
		ID:                  v.ID,
		Titular:             v.Titular,
		TipoDocumento:       v.TipoDocumento,
		TipoVisitante:       v.TipoVisitante,
		Curp:                v.Curp,
		FotoDocumentoURL:    v.FotoDocumentoURL,
		NitidezIneScore:     v.NitidezIneScore,
		CalidadIne:          v.CalidadIne,
		FotoRostroURL:       v.FotoRostroURL,
		FotoPlacaURL:        v.FotoPlacaURL,
		CasaDestino:         v.CasaDestino,
		Motivo:              v.Motivo,
		Placa:               v.Placa,
		Estado:              v.Estado,
		Intervenida:         v.Intervenida,
		KioskoID:            v.KioskoID,
		AutorizadoPorTipo:   v.AutorizadoPorTipo,
		AutorizadoPorNombre: v.AutorizadoPorNombre,
		AutorizadoPorCorreo: v.AutorizadoPorCorreo,
		AutorizadoPorRol:    v.AutorizadoPorRol,
		CreatedAt:           v.CreatedAt,
	}
	aplicarAnalisisIA(&resp.ResumenIA, &resp.ScoreIA, v)
	return resp
}

// helper func para convertir una Visita (DB Model) a DTO VisitaListItemResponse
// pensado para iterar visitas y retornar []VisitaListItemResponse
func toVisitaListItemResponse(v Visita) VisitaListItemResponse {
	item := VisitaListItemResponse{
		ID:                  v.ID,
		Titular:             v.Titular,
		TipoVisitante:       v.TipoVisitante,
		TipoDocumento:       v.TipoDocumento,
		CasaDestino:         v.CasaDestino,
		Motivo:              v.Motivo,
		Estado:              v.Estado,
		Intervenida:         v.Intervenida,
		KioskoID:            v.KioskoID,
		AutorizadoPorTipo:   v.AutorizadoPorTipo,
		AutorizadoPorNombre: v.AutorizadoPorNombre,
		AutorizadoPorCorreo: v.AutorizadoPorCorreo,
		AutorizadoPorRol:    v.AutorizadoPorRol,
		CreatedAt:           v.CreatedAt,
	}
	aplicarAnalisisIA(&item.ResumenIA, &item.ScoreIA, v)
	return item
}

// aplicarAnalisisIA rellena resumen_ia/score_ia de forma independiente: el
// LLM puede fallar (timeout, servidor caído) sin que eso invalide las
// heurísticas ya calculadas — se persisten y exponen por separado para no
// esconder el score cuando solo el resumen narrativo no llegó.
func aplicarAnalisisIA(resumenIA **string, scoreIA **ScoreIA, v Visita) {
	if v.ScoreIA != nil {
		var score ScoreIA
		if err := json.Unmarshal(v.ScoreIA, &score); err == nil {
			*scoreIA = &score
		}
	}
	if v.ResumenIA != "" {
		resumen := v.ResumenIA
		*resumenIA = &resumen
	} else if *scoreIA != nil {
		resumen := (*scoreIA).GenerarResumenHeuristico()
		*resumenIA = &resumen
	}
}
