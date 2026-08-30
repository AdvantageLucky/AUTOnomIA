package visitas

import (
	"testing"

	"kigo-autonomia-backend/internal/domain/kiosko"
)

func TestValidarCamposCondicionales_VehicularSinInvitacion_SinFotoPlacaVisitante_NoRechaza(t *testing.T) {
	// Reproduce el bug reportado: registro vehicular sin invitación, con
	// placa (texto) capturada pero sin foto de placa (el kiosko no tiene
	// hoy ningún mecanismo real de capturarla) -- config con
	// FotoPlacaVisitante en su default real (false).
	cfg := &kiosko.KioskoConfig{
		FotoPlacaVisitante:  false,
		FotoRostroVisitante: false,
	}
	req := VisitaRequest{
		TipoVisitante: TipoSinInvitacion,
		Titular:       "",
		Placa:         "ABC123D",
		FotoPlaca:     nil,
	}

	msg := ValidarCamposCondicionales(req, cfg, kiosko.KioskoVehicular)
	if msg != "" {
		t.Errorf("esperaba que pasara sin error, got %q", msg)
	}
}

func TestValidarCamposCondicionales_VehicularSinInvitacion_SinPlacaTexto_Rechaza(t *testing.T) {
	// La placa como TEXTO sigue siendo obligatoria en vehicular sin
	// invitación (es el identificador de la visita, ADR-0024) -- eso no
	// cambia con este fix.
	cfg := &kiosko.KioskoConfig{FotoPlacaVisitante: false}
	req := VisitaRequest{
		TipoVisitante: TipoSinInvitacion,
		Placa:         "",
	}

	msg := ValidarCamposCondicionales(req, cfg, kiosko.KioskoVehicular)
	if msg != "placa es requerida según la configuración del kiosko" {
		t.Errorf("esperaba error de placa requerida, got %q", msg)
	}
}

func TestValidarCamposCondicionales_VehicularSinInvitacion_ConFotoPlacaVisitanteActivo_ExigeFoto(t *testing.T) {
	// Si el admin sí activó explícitamente "exigir foto de placa" en el
	// dashboard, el kiosko debe seguir respetando esa config -- el fix solo
	// deja de FORZAR el requisito, no lo elimina cuando se pide a propósito.
	cfg := &kiosko.KioskoConfig{FotoPlacaVisitante: true}
	req := VisitaRequest{
		TipoVisitante: TipoSinInvitacion,
		Placa:         "ABC123D",
		FotoPlaca:     nil,
	}

	msg := ValidarCamposCondicionales(req, cfg, kiosko.KioskoVehicular)
	if msg != "foto_placa es requerida según la configuración del kiosko" {
		t.Errorf("esperaba error de foto_placa requerida, got %q", msg)
	}
}
