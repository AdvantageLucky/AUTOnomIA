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
	var reqIne, reqRostro, reqPlacaTexto, reqFotoPlaca bool

	switch req.TipoVisitante {

	case TipoSinInvitacion:
		reqIne = cfg.FotoIneVisitante
		reqRostro = cfg.FotoRostroVisitante
		if tipoKiosko == kiosko.KioskoVehicular {
			// La placa (texto) siempre identifica la visita vehicular sin
			// invitación (ADR-0024) — eso no depende de la config. La FOTO
			// de placa sí depende de cfg.FotoPlacaVisitante, igual que en
			// peatonal: antes se exigía siempre sin importar la config, lo
			// cual rechazaba TODO registro vehicular porque el kiosko no
			// tiene hoy ningún mecanismo real de capturar esa foto (el
			// hardware dedicado está mockeado, el OCR por foto es código
			// muerto sin usar).
			reqPlacaTexto = true
			reqFotoPlaca = cfg.FotoPlacaVisitante
		} else {
			reqPlacaTexto = cfg.FotoPlacaVisitante
			reqFotoPlaca = cfg.FotoPlacaVisitante
		}

	case TipoConInvitacion:
		reqIne = cfg.IneObligatorioInvitado
		reqRostro = cfg.FotoRostroInvitado
		reqPlacaTexto = cfg.FotoPlacaInvitado
		reqFotoPlaca = cfg.FotoPlacaInvitado
	}

	// El titular sale de la INE, de la placa o de la invitación. Si no hay ninguna
	// y tampoco viene explícito, no bloquea si al menos hay foto de rostro o destino
	if strings.TrimSpace(req.Titular) == "" && !reqIne && !reqPlacaTexto && !reqRostro {
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

	if reqPlacaTexto && strings.TrimSpace(req.Placa) == "" {
		return "placa es requerida según la configuración del kiosko"
	}
	if reqFotoPlaca && req.FotoPlaca == nil {
		return "foto_placa es requerida según la configuración del kiosko"
	}

	return ""
}
