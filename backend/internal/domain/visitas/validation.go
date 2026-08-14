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
		if tipoKiosko == kiosko.KioskoVehicular {
			// En un acceso vehicular el conductor no baja del coche: pedirle la INE
			// detiene la fila. La matrícula toma su lugar como identificador de la
			// visita, así que aquí es obligatoria sin importar el toggle (ADR-0024).
			reqIne = false
			reqPlaca = true
		} else {
			// En el peatonal la INE sigue siendo la única forma de construir el
			// historial de una persona (ADR-0016).
			reqIne = true
			reqPlaca = cfg.FotoPlacaVisitante
		}
		reqRostro = cfg.FotoRostroVisitante

	case TipoConInvitacion:
		reqIne = cfg.IneObligatorioInvitado
		reqRostro = cfg.FotoRostroInvitado
		reqPlaca = cfg.FotoPlacaInvitado
	}

	// El titular sale de la INE o de la invitación. Si no hay ninguna de las dos,
	// el handler lo rellena con la placa; sin ningún identificador la visita
	// quedaría imposible de encontrar después en la bitácora.
	if strings.TrimSpace(req.Titular) == "" && !reqIne && !reqPlaca {
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
