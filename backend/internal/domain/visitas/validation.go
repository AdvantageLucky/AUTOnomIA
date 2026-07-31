package visitas

import (
	"strings"

	"kigo-autonomia-backend/internal/domain/kiosko"
)

// validarCamposCondicionales valida los campos opcionales de VisitaRequest
// segun el TipoVisitante y la configuración del kiosko, despues
// devuelve un mensaje de error listo para enviar al cliente, o "" si todo esta bien
func validarCamposCondicionales(req VisitaRequest, cfg *kiosko.KioskoConfig) string {
	var reqIne, reqRostro, reqPlaca bool

	switch req.TipoVisitante {

	// en el caso SinInvitacion siempre se pedira
	// ine para asegurar busquedas en visitas
	case TipoSinInvitacion:
		reqIne = true
		reqRostro = cfg.FotoRostroVisitante
		reqPlaca = cfg.FotoPlacaVisitante
	case TipoConInvitacion:
		reqIne = cfg.IneObligatorioInvitado
		reqRostro = cfg.FotoRostroInvitado
		reqPlaca = cfg.FotoPlacaInvitado
	}

	if reqIne {
		if req.TipoDocumento == "" {
			return "tipo_documento es requerido para este tipo de visitante"
		}
		if len(req.Curp) != 18 {
			return "curp debe tener 18 caracteres"
		}
		if req.FotoDocumento == nil {
			return "foto_documento es requerida para este tipo de visitante"
		}
	}

	if reqRostro && req.FotoRostro == nil {
		return "foto_rostro es requerida según la configuración del kiosko"
	}

	if reqPlaca {
		if strings.TrimSpace(req.Placa) == "" {
			return "placa es requerida según la configuración del kiosko"
		}
		if req.FotoPlaca == nil {
			return "foto_placa es requerida según la configuración del kiosko"
		}
	}

	return ""
}
