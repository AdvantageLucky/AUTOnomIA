package visitas

import (
	"encoding/json"
	"strings"
	"testing"
	"time"

	"gorm.io/gorm"
)

func TestAnalizarVisita_PrimeraVisita(t *testing.T) {
	nueva := Visita{Titular: "García Juan", Curp: "GARJ900101HMCRNA01"}
	sc := AnalizarVisita(nil, nueva, EvidenciaEsperada{})

	if sc.VecesVisitado != 0 {
		t.Errorf("esperaba 0 visitas previas, got %d", sc.VecesVisitado)
	}
	if sc.Confiable {
		t.Error("primera visita no debe ser confiable")
	}
}

func TestAnalizarVisita_AltaConfianza(t *testing.T) {
	historial := make([]Visita, 6)
	for i := range historial {
		historial[i] = Visita{Estado: EstadoAprobado, Placa: "ABC123"}
	}
	nueva := Visita{Placa: "ABC123", Curp: "GARJ900101HMCRNA01"}
	sc := AnalizarVisita(historial, nueva, EvidenciaEsperada{})

	if !sc.Confiable {
		t.Error("6 aprobaciones seguidas con placa y CURP validas deben dar confianza alta")
	}
}

func TestAnalizarVisita_AnomaliaMatricula(t *testing.T) {
	historial := []Visita{
		{Placa: "ABC123", Estado: EstadoAprobado},
		{Placa: "ABC123", Estado: EstadoAprobado},
	}
	nueva := Visita{Placa: "XYZ999", Curp: "GARJ900101HMCRNA01"}
	sc := AnalizarVisita(historial, nueva, EvidenciaEsperada{})

	if !sc.AnomaliaMatricula {
		t.Error("placa diferente debe marcar AnomaliaMatricula")
	}
}

func TestAnalizarVisita_OCRSospechoso_CURPInvalida(t *testing.T) {
	nueva := Visita{Titular: "García Juan", Curp: "INVALIDA"}
	sc := AnalizarVisita(nil, nueva, EvidenciaEsperada{})

	if !sc.OCRSospechoso {
		t.Error("CURP inválida debe marcar OCRSospechoso")
	}
}

// Un acceso vehicular no captura INE: la visita llega sin CURP y eso no es una
// anomalía. Tratarlo como OCR sospechoso dejaría a esos kioskos sin autopass.
func TestAnalizarVisita_SinCURP_NoEsOCRSospechoso(t *testing.T) {
	nueva := Visita{Placa: "ABC123D", TipoDocumento: DocumentoPlaca}
	sc := AnalizarVisita(nil, nueva, EvidenciaEsperada{})

	if sc.OCRSospechoso {
		t.Error("una visita sin CURP no debe marcar OCRSospechoso")
	}
}

// Cuando no hay CURP el historial viene agrupado por placa, así que todas las
// matrículas son iguales por construcción y comparar no aporta nada.
func TestAnalizarVisita_SinCURP_NoComparaMatricula(t *testing.T) {
	historial := []Visita{
		{Placa: "ABC123D", Estado: EstadoAprobado},
		{Placa: "ABC123D", Estado: EstadoAprobado},
	}
	nueva := Visita{Placa: "ABC123D"}
	sc := AnalizarVisita(historial, nueva, EvidenciaEsperada{})

	if sc.AnomaliaMatricula {
		t.Error("historial agrupado por placa no debe marcar AnomaliaMatricula")
	}
}

// El visitante vehicular recurrente sí debe poder ganarse el autopass.
func TestAnalizarVisita_SinCURP_AlcanzaConfianza(t *testing.T) {
	historial := make([]Visita, 6)
	for i := range historial {
		historial[i] = Visita{Estado: EstadoAprobado, Placa: "ABC123D"}
	}
	nueva := Visita{Placa: "ABC123D", TipoDocumento: DocumentoPlaca}
	sc := AnalizarVisita(historial, nueva, EvidenciaEsperada{})

	if !sc.Confiable {
		t.Error("6 aprobaciones consecutivas de la misma placa deben marcar confiable")
	}
}

func TestAnalizarVisita_HorarioInusual(t *testing.T) {
	manana := time.Date(2026, 1, 1, 10, 0, 0, 0, time.UTC)
	historial := []Visita{
		{Estado: EstadoAprobado, Model: gorm.Model{CreatedAt: manana}},
		{Estado: EstadoAprobado, Model: gorm.Model{CreatedAt: manana}},
		{Estado: EstadoAprobado, Model: gorm.Model{CreatedAt: manana}},
	}
	noche := time.Date(2026, 1, 2, 23, 0, 0, 0, time.UTC)
	nueva := Visita{Curp: "GARJ900101HMCRNA01", Model: gorm.Model{CreatedAt: noche}}
	sc := AnalizarVisita(historial, nueva, EvidenciaEsperada{})

	if !sc.HorarioInusual {
		t.Error("llegada nocturna cuando historial es diurno debe marcar HorarioInusual")
	}
}

func TestAnalizarVisita_HorarioInusual_MedianocheWrap(t *testing.T) {
	// Visitas habituales a las 23:50
	noche := time.Date(2026, 1, 1, 23, 50, 0, 0, time.UTC)
	historial := []Visita{
		{Estado: EstadoAprobado, Model: gorm.Model{CreatedAt: noche}},
		{Estado: EstadoAprobado, Model: gorm.Model{CreatedAt: noche}},
		{Estado: EstadoAprobado, Model: gorm.Model{CreatedAt: noche}},
	}
	// Llegada a las 00:10 (20 minutos después, cruzando medianoche)
	madrugada := time.Date(2026, 1, 2, 0, 10, 0, 0, time.UTC)
	nueva := Visita{Curp: "GARJ900101HMCRNA01", Model: gorm.Model{CreatedAt: madrugada}}
	sc := AnalizarVisita(historial, nueva, EvidenciaEsperada{})

	if sc.HorarioInusual {
		t.Error("llegada a las 00:10 cuando historial es 23:50 no debe marcar HorarioInusual (cruce de medianoche)")
	}
}

func TestScoreContexto_AScoreIA(t *testing.T) {
	ahora := time.Now()
	sc := ScoreContexto{
		VecesVisitado:     3,
		UltimaVisita:      &ahora,
		AnomaliaMatricula: true,
		CambioModalidad:   true, // no debe aparecer en ScoreIA
		HorarioInusual:    false,
		RechazadoPrevio:   true,
		OCRSospechoso:     false,
		Confiable:         false,
		ResumenTexto:      "texto que tampoco debe aparecer",
	}

	got := sc.AScoreIA()

	if got.VecesVisitado != 3 || got.UltimaVisita != &ahora {
		t.Errorf("VecesVisitado/UltimaVisita no se copiaron bien: %+v", got)
	}
	if !got.AnomaliaMatricula || !got.RechazadoPrevio {
		t.Errorf("anomalías no se copiaron bien: %+v", got)
	}
	if got.HorarioInusual || got.Confiable {
		t.Errorf("esperaba HorarioInusual/Confiable en false, got %+v", got)
	}

	data, err := json.Marshal(got)
	if err != nil {
		t.Fatalf("no esperaba error al serializar: %v", err)
	}
	if strings.Contains(string(data), "cambio_modalidad") || strings.Contains(string(data), "resumen") {
		t.Errorf("ScoreIA no debe exponer cambio_modalidad ni resumen: %s", data)
	}
}
