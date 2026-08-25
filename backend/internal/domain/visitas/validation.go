package visitas

import (
	"strings"

	"kigo-autonomia-backend/internal/domain/kiosko"
)

// ValidarCamposCondicionales valida los campos opcionales de VisitaRequest
// segun el TipoVisitante, el tipo de acceso y la configuración del kiosko, despues
// devuelve un mensaje de error listo para enviar al cliente, o "" si todo esta bien
func ValidarCamposCondicionales(
	req VisitaRequest,
	cfg *kiosko.KioskoConfig,
	tipoKiosko kiosko.TipoKiosko,
) string {
	var reqIne, reqRostro, reqPlaca bool

	switch req.TipoVisitante {

	case TipoSinInvitacion:
		reqIne = cfg.FotoIneVisitante
		if tipoKiosko == kiosko.KioskoVehicular {
			reqPlaca = true
		} else {
			reqPlaca = cfg.FotoPlacaVisitante
		}
		reqRostro = cfg.FotoRostroVisitante

	case TipoConInvitacion:
		reqIne = cfg.IneObligatorioInvitado
		reqRostro = cfg.FotoRostroInvitado
		reqPlaca = cfg.FotoPlacaInvitado
	}

	// El titular sale de la INE, de la placa o de la invitación. Si no hay ninguna
	// y tampoco viene explícito, no bloquea si al menos hay foto de rostro o destino
	if strings.TrimSpace(req.Titular) == "" && !reqIne && !reqPlaca && !reqRostro {
		return "titular es requerido"
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
