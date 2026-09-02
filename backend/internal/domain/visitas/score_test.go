package visitas

import (
	"strings"
	"testing"

	"kigo-autonomia-backend/internal/domain/kiosko"
)

func historialAprobado(n int, placa string) []Visita {
	h := make([]Visita, n)
	for i := range h {
		h[i] = Visita{Estado: EstadoAprobado, Placa: placa}
	}
	return h
}

func factorPorClave(sc ScoreContexto, clave string) *FactorScore {
	for i := range sc.Factores {
		if sc.Factores[i].Clave == clave {
			return &sc.Factores[i]
		}
	}
	return nil
}

func TestScore_DesconocidoQuedaEnLaBase(t *testing.T) {
	sc := AnalizarVisita(nil, Visita{Titular: "Ana"}, EvidenciaEsperada{}, fuentesTodas)
	// Base 50 menos la penalización de "sin historial".
	if sc.ConfianzaPct >= 55 {
		t.Errorf("un desconocido sin evidencia no debe llegar a confianza media, got %d", sc.ConfianzaPct)
	}
	if sc.NivelConfianza() != "baja" {
		t.Errorf("esperaba confianza baja, got %q", sc.NivelConfianza())
	}
}

func TestScore_RecurrenteLimpioLlegaAAlta(t *testing.T) {
	nueva := Visita{
		Placa: "ABC123", Curp: "GARJ900101HMCRNA01",
		FotoRostroURL: "/r.jpg", FotoDocumentoURL: "/d.jpg", CalidadIne: "nitida",
	}
	sc := AnalizarVisita(historialAprobado(6, "ABC123"), nueva,
		EvidenciaEsperada{Rostro: true, Documento: true}, fuentesTodas)

	if sc.NivelConfianza() != "alta" {
		t.Errorf("recurrente con evidencia completa debe dar confianza alta, got %d (%s)",
			sc.ConfianzaPct, sc.NivelConfianza())
	}
	if !sc.PuedeAutoPass(80) {
		t.Error("esperaba que pasara el umbral de autopase de 80")
	}
}

// El caso que motivó EvidenciaEsperada: una caseta vehicular no captura INE,
// y penalizar su ausencia dejaba a esos kioskos sin autopase para siempre.
func TestScore_VehicularNoSePenalizaPorINEQueNadiePidio(t *testing.T) {
	nueva := Visita{Placa: "ABC123D", TipoDocumento: DocumentoPlaca}
	historial := historialAprobado(6, "ABC123D")

	conINE := AnalizarVisita(historial, nueva, EvidenciaEsperada{Documento: true}, fuentesTodas)
	sinINE := AnalizarVisita(historial, nueva, EvidenciaEsperada{Placa: true}, fuentesTodas)

	if factorPorClave(sinINE, "sin_documento") != nil {
		t.Error("no debe marcarse documento faltante si el kiosko no lo pedia")
	}
	if factorPorClave(conINE, "sin_documento") == nil {
		t.Error("si el kiosko si lo pedia, debe marcarse como faltante")
	}
	if sinINE.ConfianzaPct <= conINE.ConfianzaPct {
		t.Errorf("no exigir INE no puede puntuar peor que exigirla y no tenerla: %d vs %d",
			sinINE.ConfianzaPct, conINE.ConfianzaPct)
	}
}

func TestScore_BloqueantesImpidenAutopaseAunqueElScoreAlcance(t *testing.T) {
	historial := historialAprobado(8, "ABC123")
	historial[0].Estado = EstadoRechazado

	nueva := Visita{
		Placa: "ABC123", Curp: "GARJ900101HMCRNA01",
		FotoRostroURL: "/r.jpg", FotoDocumentoURL: "/d.jpg", CalidadIne: "nitida",
	}
	sc := AnalizarVisita(historial, nueva, EvidenciaEsperada{Rostro: true, Documento: true}, fuentesTodas)

	if !sc.Bloqueantes() {
		t.Fatal("un rechazo previo debe contar como bloqueante")
	}
	if sc.PuedeAutoPass(0) {
		t.Error("con umbral 0 el score sobra, pero un bloqueante debe impedir el autopase igual")
	}
}

func TestScore_MatchDeRostroSuma(t *testing.T) {
	base := Visita{FotoRostroURL: "/r.jpg"}
	conMatch := Visita{FotoRostroURL: "/r.jpg", TipoDocumento: DocumentoRostro}

	sinSc := AnalizarVisita(nil, base, EvidenciaEsperada{}, fuentesTodas)
	conSc := AnalizarVisita(nil, conMatch, EvidenciaEsperada{}, fuentesTodas)

	if factorPorClave(conSc, "match_rostro") == nil {
		t.Error("una entrada resuelta por reconocimiento facial debe registrar el match")
	}
	if conSc.ConfianzaPct <= sinSc.ConfianzaPct {
		t.Errorf("el match de rostro debe subir la confianza: %d vs %d",
			conSc.ConfianzaPct, sinSc.ConfianzaPct)
	}
}

func TestScore_PlacaDistintaRestaYRecomienda(t *testing.T) {
	nueva := Visita{Placa: "XYZ999", Curp: "GARJ900101HMCRNA01"}
	sc := AnalizarVisita(historialAprobado(4, "ABC123"), nueva, EvidenciaEsperada{}, fuentesTodas)

	f := factorPorClave(sc, "placa_distinta")
	if f == nil {
		t.Fatal("esperaba el factor de placa distinta")
	}
	if f.Impacto >= 0 {
		t.Errorf("una placa que no cuadra debe restar, got %d", f.Impacto)
	}
	if !contieneSubcadena(sc.Recomendaciones, "confirmar la placa") {
		t.Errorf("esperaba una recomendacion sobre la placa, got %v", sc.Recomendaciones)
	}
}

func TestScore_EvidenciaFaltanteSaleComoRecomendacion(t *testing.T) {
	sc := AnalizarVisita(nil, Visita{Titular: "Ana"}, EvidenciaEsperada{Rostro: true}, fuentesTodas)

	if factorPorClave(sc, "sin_rostro") == nil {
		t.Error("esperaba el factor de rostro faltante")
	}
	if !contieneSubcadena(sc.Recomendaciones, "Falta la foto de rostro") {
		t.Errorf("esperaba que el faltante se tradujera a una accion, got %v", sc.Recomendaciones)
	}
}

func TestScore_SiempreEntre0Y100(t *testing.T) {
	// Todo en contra a la vez: sin el acote, la suma se iria por debajo de 0.
	historial := historialAprobado(1, "ABC123")
	historial[0].Estado = EstadoRechazado
	pesima := Visita{Placa: "XYZ999", Curp: "NO-ES-CURP"}
	sc := AnalizarVisita(historial, pesima, EvidenciaEsperada{Rostro: true, Documento: true, Placa: true}, fuentesTodas)
	if sc.ConfianzaPct < 0 || sc.ConfianzaPct > 100 {
		t.Errorf("score fuera de rango: %d", sc.ConfianzaPct)
	}

	optima := Visita{
		Placa: "ABC123", Curp: "GARJ900101HMCRNA01", TipoDocumento: DocumentoRostro,
		FotoRostroURL: "/r.jpg", FotoDocumentoURL: "/d.jpg", CalidadIne: "nitida",
		PersonaID: new(uint),
	}
	sc = AnalizarVisita(historialAprobado(20, "ABC123"), optima, EvidenciaEsperada{}, fuentesTodas)
	if sc.ConfianzaPct > 100 {
		t.Errorf("score por encima de 100: %d", sc.ConfianzaPct)
	}
}

func TestEvidenciaEsperadaDe_DistingueInvitadoDeWalkIn(t *testing.T) {
	cfg := &kiosko.KioskoConfig{
		FotoRostroVisitante: true, FotoIneVisitante: true, FotoPlacaVisitante: true,
		FotoRostroInvitado: true, IneObligatorioInvitado: false, FotoPlacaInvitado: false,
	}

	walkIn := evidenciaEsperadaDe(cfg, Visita{TipoVisitante: TipoSinInvitacion})
	if !walkIn.Rostro || !walkIn.Documento || !walkIn.Placa {
		t.Errorf("walk-in debe heredar los requisitos de visitante, got %+v", walkIn)
	}

	invitado := evidenciaEsperadaDe(cfg, Visita{TipoVisitante: TipoConInvitacion})
	if !invitado.Rostro || invitado.Documento || invitado.Placa {
		t.Errorf("al invitado solo se le pide lo suyo, got %+v", invitado)
	}

	// Un residente entra por PIN o match facial contra su enrolamiento, no
	// por el flujo de visitante -- no hereda FotoRostroVisitante/etc. del
	// kiosko aunque estén activados, porque su acceso nunca los captura.
	residente := evidenciaEsperadaDe(cfg, Visita{TipoVisitante: TipoResidente})
	if (residente != EvidenciaEsperada{}) {
		t.Errorf("a un residente no se le debe exigir nada del flujo de visitante, got %+v", residente)
	}

	if (evidenciaEsperadaDe(nil, Visita{}) != EvidenciaEsperada{}) {
		t.Error("sin config no se debe exigir nada")
	}
}

func contieneSubcadena(xs []string, sub string) bool {
	for _, x := range xs {
		if strings.Contains(strings.ToLower(x), strings.ToLower(sub)) {
			return true
		}
	}
	return false
}
