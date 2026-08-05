package visitas

import (
	"testing"
	"time"

	"gorm.io/gorm"
)

func TestAnalizarVisita_PrimeraVisita(t *testing.T) {
	nueva := Visita{Titular: "García Juan", Curp: "GARJ900101HMCRNA01"}
	sc := AnalizarVisita(nil, nueva, 5)

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
	sc := AnalizarVisita(historial, nueva, 5)

	if !sc.Confiable {
		t.Error("6 aprobaciones consecutivas deben marcar confiable con umbral 5")
	}
}

func TestAnalizarVisita_AnomaliaMatricula(t *testing.T) {
	historial := []Visita{
		{Placa: "ABC123", Estado: EstadoAprobado},
		{Placa: "ABC123", Estado: EstadoAprobado},
	}
	nueva := Visita{Placa: "XYZ999", Curp: "GARJ900101HMCRNA01"}
	sc := AnalizarVisita(historial, nueva, 5)

	if !sc.AnomaliaMatricula {
		t.Error("placa diferente debe marcar AnomaliaMatricula")
	}
}

func TestAnalizarVisita_OCRSospechoso_CURPInvalida(t *testing.T) {
	nueva := Visita{Titular: "García Juan", Curp: "INVALIDA"}
	sc := AnalizarVisita(nil, nueva, 5)

	if !sc.OCRSospechoso {
		t.Error("CURP inválida debe marcar OCRSospechoso")
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
	sc := AnalizarVisita(historial, nueva, 5)

	if !sc.HorarioInusual {
		t.Error("llegada nocturna cuando historial es diurno debe marcar HorarioInusual")
	}
}
