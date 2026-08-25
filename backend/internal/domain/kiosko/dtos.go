/*
Package kiosko

DTOs relacionados a el dominio kiosko
Representan respuestas o peticiones relacionados con el modelo Kiosko
Usado en endpoints para recibir una respuesta o enviar una respuesta con un cuerpo en especifico
*/
package kiosko

import "encoding/json"

// RegisterKioskoRequest DTO para dar de alta o modificar un kiosko
type RegisterKioskoRequest struct {
	Nombre    string     `json:"nombre"    binding:"required"`
	Ubicacion string     `json:"ubicacion"`
	Tipo      TipoKiosko `json:"tipo"      binding:"required,oneof=PEATONAL VEHICULAR"`
}

// KioskoResponse DTO para devolver info de un kiosko despues de ser creado/modificado
// ClaveKiosko solo viaja en la respuesta de RegisterKiosko (texto plano, una sola vez); en cualquier
// otra respuesta queda vacio y se omite del JSON, porque el servidor solo guarda su hash bcrypt
type KioskoResponse struct {
	ID          uint       `json:"id"`
	Nombre      string     `json:"nombre"`
	Tipo        TipoKiosko `json:"tipo"`
	Ubicacion   string     `json:"ubicacion"`
	AdminID     uint       `json:"usuario_id"`
	ClaveKiosko string     `json:"clave_kiosko,omitempty"`
}

// KioskoConfigRequest DTO para actualizar la config de un kiosko
type KioskoConfigRequest struct {
	ColorKiosko            *string   `json:"color_kiosko"`
	IdiomaKiosko           *string   `json:"idioma_kiosko"`
	FotoPlacaVisitante     *bool     `json:"foto_placa_visitante"`
	FotoRostroVisitante    *bool     `json:"foto_rostro_visitante"`
	FotoIneVisitante       *bool     `json:"foto_ine_visitante"`
	PasosSinInvitacion     *[]string `json:"pasos_sin_invitacion"`
	FotoPlacaInvitado      *bool     `json:"foto_placa_invitado"`
	FotoRostroInvitado     *bool     `json:"foto_rostro_invitado"`
	IneObligatorioInvitado *bool     `json:"foto_ine_invitado"`
	TiempoEsperaSeg        *int      `json:"tiempo_espera_seg"`
	HorarioInicio          *string   `json:"horario_inicio"`
	HorarioFin             *string   `json:"horario_fin"`
	MensajeBienvenida      *string   `json:"mensaje_bienvenida"`
	AutoPassHabilitado     *bool     `json:"auto_pass_habilitado"`
	UmbralConfianzaVisitas *int      `json:"umbral_confianza_visitas"`
	UmbralSimilitudCara    *float64  `json:"umbral_similitud_cara"`
}

// KioskoConfigResponse DTO de respuesta de la config del kiosko
//
// Tipo no vive en KioskoConfig sino en Kiosko, pero viaja aqui porque la app del
// kiosko solo consume este DTO (GET /config/mia y el stream SSE) y necesita el
// tipo para decidir que flujo montar: peatonal o vehicular (ver ADR-0022)
type KioskoConfigResponse struct {
	KioskoID               uint       `json:"kiosko_id"`
	Tipo                   TipoKiosko `json:"tipo"`
	ColorKiosko            string     `json:"color_kiosko"`
	IdiomaKiosko           string     `json:"idioma_kiosko"`
	FotoPlacaVisitante     bool       `json:"foto_placa_visitante"`
	FotoRostroVisitante    bool       `json:"foto_rostro_visitante"`
	FotoIneVisitante       bool       `json:"foto_ine_visitante"`
	PasosSinInvitacion     []string   `json:"pasos_sin_invitacion"`
	FotoPlacaInvitado      bool       `json:"foto_placa_invitado"`
	FotoRostroInvitado     bool       `json:"foto_rostro_invitado"`
	IneObligatorioInvitado bool       `json:"foto_ine_invitado"`
	TiempoEsperaSeg        int        `json:"tiempo_espera_seg"`
	HorarioInicio          string     `json:"horario_inicio"`
	HorarioFin             string     `json:"horario_fin"`
	MensajeBienvenida      string     `json:"mensaje_bienvenida"`
	AutoPassHabilitado     bool       `json:"auto_pass_habilitado"`
	UmbralConfianzaVisitas int        `json:"umbral_confianza_visitas"`
	UmbralSimilitudCara    float64    `json:"umbral_similitud_cara"`
}

// helper func para convertir un Kiosko (DB Model) a DTO Reponse
func toKioskoResponse(a *Kiosko) KioskoResponse {
	return KioskoResponse{
		ID:        a.ID,
		Nombre:    a.Nombre,
		Ubicacion: a.Ubicacion,
		Tipo:      a.Tipo,
		AdminID:   a.AdminID,
	}
}

// helper func para convertir un KioskoConfig (DB Model) a DTO Response
// tipo se recibe aparte porque pertenece al Kiosko, no a su config
func toKioskoConfigResponse(cfg *KioskoConfig, tipo TipoKiosko) KioskoConfigResponse {
	var pasos []string
	if cfg.PasosSinInvitacion != "" {
		_ = json.Unmarshal([]byte(cfg.PasosSinInvitacion), &pasos)
	}
	if len(pasos) == 0 {
		if tipo == KioskoVehicular {
			pasos = []string{"PLACA", "ROSTRO", "DESTINO"}
		} else {
			pasos = []string{"ROSTRO", "DESTINO"}
		}
	}

	return KioskoConfigResponse{
		KioskoID:     cfg.KioskoID,
		Tipo:         tipo,
		ColorKiosko:  cfg.ColorKiosko,
		IdiomaKiosko: cfg.IdiomaKiosko,

		// SinInvitacion
		FotoPlacaVisitante:  cfg.FotoPlacaVisitante,
		FotoRostroVisitante: cfg.FotoRostroVisitante,
		FotoIneVisitante:    cfg.FotoIneVisitante,
		PasosSinInvitacion:  pasos,

		// ConInvitacion
		FotoPlacaInvitado:      cfg.FotoPlacaInvitado,
		FotoRostroInvitado:     cfg.FotoRostroInvitado,
		IneObligatorioInvitado: cfg.IneObligatorioInvitado,

		TiempoEsperaSeg:        cfg.TiempoEsperaSeg,
		HorarioInicio:          cfg.HorarioInicio,
		HorarioFin:             cfg.HorarioFin,
		MensajeBienvenida:      cfg.MensajeBienvenida,
		AutoPassHabilitado:     cfg.AutoPassHabilitado,
		UmbralConfianzaVisitas: cfg.UmbralConfianzaVisitas,
		UmbralSimilitudCara:    cfg.UmbralSimilitudCara,
	}
}
