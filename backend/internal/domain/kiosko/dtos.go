/*
Package kiosko

DTOs relacionados a el dominio kiosko
Representan respuestas o peticiones relacionados con el modelo Kiosko
Usado en endpoints para recibir una respuesta o enviar una respuesta con un cuerpo en especifico
*/
package kiosko

// RegisterKioskoRequest DTO para dar de alta o modificar un kiosko
type RegisterKioskoRequest struct {
	Nombre    string `json:"nombre"    binding:"required"`
	Ubicacion string `json:"ubicacion"`
}

// KioskoResponse DTO para devolver info de un kiosko despues de ser creado/modificado
// ClaveKiosko solo viaja en la respuesta de RegisterKiosko (texto plano, una sola vez); en cualquier
// otra respuesta queda vacio y se omite del JSON, porque el servidor solo guarda su hash bcrypt
type KioskoResponse struct {
	ID          uint   `json:"id"`
	Nombre      string `json:"nombre"`
	Ubicacion   string `json:"ubicacion"`
	AdminID     uint   `json:"usuario_id"`
	ClaveKiosko string `json:"clave_kiosko,omitempty"`
}

// KioskoConfigRequest DTO para actualizar la config de un kiosko
type KioskoConfigRequest struct {
	ColorKiosko                *string `json:"color_kiosko"`
	IdiomaKiosko               *string `json:"idioma_kiosko"`
	FotoPlacaVisitante         *bool   `json:"foto_placa_visitante"`
	FotoRostroVisitante        *bool   `json:"foto_rostro_visitante"`
	FotoPlacaInvitado          *bool   `json:"foto_placa_invitado"`
	FotoRostroInvitado         *bool   `json:"foto_rostro_invitado"`
	IneObligatorioInvitado *bool   `json:"foto_ine_invitado"`
	TiempoEsperaMin            *int    `json:"tiempo_espera_min"`
	HorarioInicio              *string `json:"horario_inicio"`
	HorarioFin                 *string `json:"horario_fin"`
	MensajeBienvenida          *string `json:"mensaje_bienvenida"`
	AutoPassHabilitado         *bool   `json:"auto_pass_habilitado"`
	UmbralConfianzaVisitas     *int    `json:"umbral_confianza_visitas"`
}

// KioskoConfigResponse DTO de respuesta de la config del kiosko
type KioskoConfigResponse struct {
	KioskoID                   uint   `json:"kiosko_id"`
	ColorKiosko                string `json:"color_kiosko"`
	IdiomaKiosko               string `json:"idioma_kiosko"`
	FotoPlacaVisitante         bool   `json:"foto_placa_visitante"`
	FotoRostroVisitante        bool   `json:"foto_rostro_visitante"`
	FotoPlacaInvitado          bool   `json:"foto_placa_invitado"`
	FotoRostroInvitado         bool   `json:"foto_rostro_invitado"`
	IneObligatorioInvitado bool   `json:"foto_ine_invitado"`
	TiempoEsperaMin            int    `json:"tiempo_espera_min"`
	HorarioInicio              string `json:"horario_inicio"`
	HorarioFin                 string `json:"horario_fin"`
	MensajeBienvenida          string `json:"mensaje_bienvenida"`
	AutoPassHabilitado         bool   `json:"auto_pass_habilitado"`
	UmbralConfianzaVisitas     int    `json:"umbral_confianza_visitas"`
}

// helper func para convertir un Kiosko (DB Model) a DTO Reponse
func toKioskoResponse(a *Kiosko) KioskoResponse {
	return KioskoResponse{
		ID:        a.ID,
		Nombre:    a.Nombre,
		Ubicacion: a.Ubicacion,
		AdminID:   a.AdminID,
	}
}

// helper func para convertir un KioskoConfig (DB Model) a DTO Response
func toKioskoConfigResponse(cfg *KioskoConfig) KioskoConfigResponse {
	return KioskoConfigResponse{
		KioskoID:     cfg.KioskoID,
		ColorKiosko:  cfg.ColorKiosko,
		IdiomaKiosko: cfg.IdiomaKiosko,

		// SinInvitacion
		FotoPlacaVisitante:  cfg.FotoPlacaVisitante,
		FotoRostroVisitante: cfg.FotoRostroVisitante,

		// ConInvitacion
		FotoPlacaInvitado:          cfg.FotoPlacaInvitado,
		FotoRostroInvitado:         cfg.FotoRostroInvitado,
		IneObligatorioInvitado: cfg.IneObligatorioInvitado,

		TiempoEsperaMin:        cfg.TiempoEsperaMin,
		HorarioInicio:          cfg.HorarioInicio,
		HorarioFin:             cfg.HorarioFin,
		MensajeBienvenida:      cfg.MensajeBienvenida,
		AutoPassHabilitado:     cfg.AutoPassHabilitado,
		UmbralConfianzaVisitas: cfg.UmbralConfianzaVisitas,
	}
}
