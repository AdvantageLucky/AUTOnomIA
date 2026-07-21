/*
Package acceso

DTOs relacionados a el dominio acceso
Representan respuestas o peticiones relacionados con el modelo Acceso
Usado en endpoints para recibir una respuesta o enviar una respuesta con un cuerpo en especifico
*/
package acceso

// RegisterAccesoRequest DTO para dar de alta o modificar un acceso
type RegisterAccesoRequest struct {
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

// AccesoConfigRequest DTO para actualizar la config de un kiosko
type AccesoConfigRequest struct {
	ColorKiosko         *string `json:"color_kiosko"`
	IdiomaKiosko        *string `json:"idioma_kiosko"`
	FotoPlacaVisitante  *bool   `json:"foto_placa_visitante"`
	FotoRostroVisitante *bool   `json:"foto_rostro_visitante"`
	FotoIneVisitante    *bool   `json:"foto_ine_visitante"`
	FotoPlacaInvitado   *bool   `json:"foto_placa_invitado"`
	FotoRostroInvitado  *bool   `json:"foto_rostro_invitado"`
	FotoIneInvitado     *bool   `json:"foto_ine_invitado"`
	TiempoEsperaMin     *int    `json:"tiempo_espera_min"`
	HorarioInicio       *string `json:"horario_inicio"`
	HorarioFin          *string `json:"horario_fin"`
	MensajeBienvenida   *string `json:"mensaje_bienvenida"`
}

// AccesoConfigResponse DTO de respuesta de la config del kiosko
type AccesoConfigResponse struct {
	AccesoID            uint   `json:"acceso_id"`
	ColorKiosko         string `json:"color_kiosko"`
	IdiomaKiosko        string `json:"idioma_kiosko"`
	FotoPlacaVisitante  bool   `json:"foto_placa_visitante"`
	FotoRostroVisitante bool   `json:"foto_rostro_visitante"`
	FotoIneVisitante    bool   `json:"foto_ine_visitante"`
	FotoPlacaInvitado   bool   `json:"foto_placa_invitado"`
	FotoRostroInvitado  bool   `json:"foto_rostro_invitado"`
	FotoIneInvitado     bool   `json:"foto_ine_invitado"`
	TiempoEsperaMin     int    `json:"tiempo_espera_min"`
	HorarioInicio       string `json:"horario_inicio"`
	HorarioFin          string `json:"horario_fin"`
	MensajeBienvenida   string `json:"mensaje_bienvenida"`
}

// helper func para convertir un Acceso (DB Model) a DTO Reponse
func toAccesoResponse(a *Acceso) AccesoResponse {
	return AccesoResponse{
		ID:        a.ID,
		Nombre:    a.Nombre,
		Ubicacion: a.Ubicacion,
		AdminID:   a.AdminID,
	}
}

// helper func para convertir un AccesoConfig (DB Model) a DTO Response
func toConfigResponse(cfg *AccesoConfig) AccesoConfigResponse {
	return AccesoConfigResponse{
		AccesoID:            cfg.AccesoID,
		ColorKiosko:         cfg.ColorKiosko,
		IdiomaKiosko:        cfg.IdiomaKiosko,
		FotoPlacaVisitante:  cfg.FotoPlacaVisitante,
		FotoRostroVisitante: cfg.FotoRostroVisitante,
		FotoIneVisitante:    cfg.FotoIneVisitante,
		FotoPlacaInvitado:   cfg.FotoPlacaInvitado,
		FotoRostroInvitado:  cfg.FotoRostroInvitado,
		FotoIneInvitado:     cfg.FotoIneInvitado,
		TiempoEsperaMin:     cfg.TiempoEsperaMin,
		HorarioInicio:       cfg.HorarioInicio,
		HorarioFin:          cfg.HorarioFin,
		MensajeBienvenida:   cfg.MensajeBienvenida,
	}
}
