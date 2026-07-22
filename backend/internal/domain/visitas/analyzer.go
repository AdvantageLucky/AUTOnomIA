package visitas

import (
	"regexp"
	"strings"
	"time"
)

var (
	reCURP         = regexp.MustCompile(`^[A-Z]{4}[0-9]{6}[HM][A-Z]{5}[A-Z0-9]{2}$`)
	reClaveElector = regexp.MustCompile(`^[A-Z]{6}[0-9]{8}[HM][0-9]{3}$`)
)

// ScoreContexto es el resultado del análisis de una visita.
// Los campos booleanos son anomalías detectadas. ResumenTexto lo rellena el cliente LLM.
type ScoreContexto struct {
	VecesVisitado     int
	UltimaVisita      *time.Time
	AnomaliaMatricula bool
	CambioModalidad   bool
	HorarioInusual    bool
	RechazadoPrevio   bool
	OCRSospechoso     bool
	Confiable         bool
	ResumenTexto      string
}

// AnalizarVisita compara la visita nueva contra el historial y devuelve el ScoreContexto.
// umbral es el número mínimo de aprobaciones consecutivas para marcar Confiable.
// historial debe estar ordenado de más reciente a más antiguo.
func AnalizarVisita(historial []Visita, nueva Visita, umbral int) ScoreContexto {
	sc := ScoreContexto{
		VecesVisitado: len(historial),
		OCRSospechoso: validarOCR(nueva.Curp, nueva.ClaveLector, nueva.Nombre),
	}

	if len(historial) == 0 {
		return sc
	}

	ultima := historial[0].CreatedAt
	sc.UltimaVisita = &ultima

	if nueva.Placa != "" {
		sc.AnomaliaMatricula = placaDiferente(historial, nueva.Placa)
	}

	for _, v := range historial {
		if v.Estado == EstadoRechazado {
			sc.RechazadoPrevio = true
			break
		}
	}

	sc.HorarioInusual = horarioInusual(historial, nueva.CreatedAt)

	sc.Confiable = esConfiable(historial, umbral) && !sc.AnomaliaMatricula && !sc.RechazadoPrevio && !sc.OCRSospechoso

	return sc
}

func validarOCR(curp, clave, nombre string) bool {
	if !reCURP.MatchString(curp) {
		return true
	}
	if len(clave) > 0 && !reClaveElector.MatchString(clave) {
		return true
	}
	if nombre != "" && len(curp) >= 1 {
		partes := strings.Fields(nombre)
		if len(partes) > 0 && strings.ToUpper(string(partes[0][0])) != string(curp[0]) {
			return true
		}
	}
	return false
}

func placaDiferente(historial []Visita, placaNueva string) bool {
	freq := map[string]int{}
	for _, v := range historial {
		if v.Placa != "" {
			freq[v.Placa]++
		}
	}
	if len(freq) == 0 {
		return false
	}
	max, maxPlaca := 0, ""
	for p, c := range freq {
		if c > max {
			max, maxPlaca = c, p
		}
	}
	return maxPlaca != placaNueva
}

func horarioInusual(historial []Visita, llegada time.Time) bool {
	if len(historial) < 3 {
		return false
	}
	var totalHoras float64
	for _, v := range historial {
		totalHoras += float64(v.CreatedAt.Hour()) + float64(v.CreatedAt.Minute())/60
	}
	promedioHora := totalHoras / float64(len(historial))
	horaLlegada := float64(llegada.Hour()) + float64(llegada.Minute())/60
	diff := horaLlegada - promedioHora
	if diff < 0 {
		diff = -diff
	}
	return diff > 4
}

func esConfiable(historial []Visita, umbral int) bool {
	if len(historial) < umbral {
		return false
	}
	for i := 0; i < umbral; i++ {
		if historial[i].Estado != EstadoAprobado {
			return false
		}
	}
	return true
}
