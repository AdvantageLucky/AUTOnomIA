package visitas

import (
	"fmt"
	"regexp"
	"strings"
	"time"
)

var reCURP = regexp.MustCompile(`^[A-Z]{4}[0-9]{6}[HM][A-Z]{5}[A-Z0-9]{2}$`)

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

// ScoreIA es el subconjunto serializable de ScoreContexto que se persiste y
// expone al dashboard — sin CambioModalidad (nunca se calcula, siempre
// false, exponerlo mentiría "sin cambios") ni ResumenTexto (va en su propia
// columna resumen_ia, no duplicado dentro del score).
type ScoreIA struct {
	VecesVisitado     int        `json:"veces_visitado"`
	UltimaVisita      *time.Time `json:"ultima_visita,omitempty"`
	AnomaliaMatricula bool       `json:"anomalia_matricula"`
	HorarioInusual    bool       `json:"horario_inusual"`
	RechazadoPrevio   bool       `json:"rechazado_previo"`
	OCRSospechoso     bool       `json:"ocr_sospechoso"`
	Confiable         bool       `json:"confiable"`
}

// GenerarResumenHeuristico genera un resumen determinista y claro en caso de que el LLM esté offline
func (s ScoreIA) GenerarResumenHeuristico() string {
	var partes []string

	if s.VecesVisitado <= 0 {
		partes = append(partes, "Primera visita registrada.")
	} else if s.VecesVisitado == 1 {
		partes = append(partes, "Segunda visita registrada.")
	} else {
		partes = append(partes, fmt.Sprintf("Visitante recurrente (%d visitas previas).", s.VecesVisitado))
	}

	if s.Confiable {
		partes = append(partes, "Visitante confiable con historial favorable.")
	}

	var anomalias []string
	if s.AnomaliaMatricula {
		anomalias = append(anomalias, "placa vehicular distinta a registros anteriores")
	}
	if s.HorarioInusual {
		anomalias = append(anomalias, "horario inusual de ingreso")
	}
	if s.RechazadoPrevio {
		anomalias = append(anomalias, "antecedente de rechazo previo")
	}
	if s.OCRSospechoso {
		anomalias = append(anomalias, "documento de identidad con formato atípico")
	}

	if len(anomalias) > 0 {
		partes = append(partes, "Atención: "+strings.Join(anomalias, ", ")+".")
	} else if s.VecesVisitado > 0 && !s.Confiable {
		partes = append(partes, "Sin anomalías detectadas.")
	}

	return strings.Join(partes, " ")
}

// AScoreIA convierte el resultado interno del análisis al subconjunto que
// se persiste y se expone al dashboard.
func (sc ScoreContexto) AScoreIA() ScoreIA {
	return ScoreIA{
		VecesVisitado:     sc.VecesVisitado,
		UltimaVisita:      sc.UltimaVisita,
		AnomaliaMatricula: sc.AnomaliaMatricula,
		HorarioInusual:    sc.HorarioInusual,
		RechazadoPrevio:   sc.RechazadoPrevio,
		OCRSospechoso:     sc.OCRSospechoso,
		Confiable:         sc.Confiable,
	}
}

// AnalizarVisita compara la visita nueva contra el historial y devuelve el ScoreContexto.
// umbral es el número mínimo de aprobaciones consecutivas para marcar Confiable.
// historial debe estar ordenado de más reciente a más antiguo.
func AnalizarVisita(historial []Visita, nueva Visita, umbral int) ScoreContexto {
	sc := ScoreContexto{
		VecesVisitado: len(historial),
		OCRSospechoso: validarOCR(nueva.Curp),
	}

	if len(historial) == 0 {
		return sc
	}

	ultima := historial[0].CreatedAt
	sc.UltimaVisita = &ultima

	// Si la visita no trae CURP, el historial vino agrupado por placa y todas las
	// matrículas son la misma por construcción: comparar no diría nada (ADR-0024).
	if nueva.Placa != "" && nueva.Curp != "" {
		sc.AnomaliaMatricula = placaDiferente(historial, nueva.Placa)
	}

	for _, v := range historial {
		if v.Estado == EstadoRechazado {
			sc.RechazadoPrevio = true
			break
		}
	}

	sc.HorarioInusual = horarioInusual(historial, nueva.CreatedAt)

	sc.Confiable = esConfiable(historial, umbral) && !sc.AnomaliaMatricula && !sc.RechazadoPrevio &&
		!sc.OCRSospechoso

	return sc
}

// validarOCR marca como sospechosa una CURP que se capturó pero salió mal formada.
// No capturarla no es sospechoso: un acceso vehicular puede no pedir INE, y tratar
// la ausencia como anomalía dejaría a esos kioskos sin autopass para siempre.
func validarOCR(curp string) bool {
	return curp != "" && !reCURP.MatchString(curp)
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
	if diff > 12 {
		diff = 24 - diff
	}
	return diff > 4
}

func esConfiable(historial []Visita, umbral int) bool {
	if len(historial) < umbral {
		return false
	}
	for i := range umbral {
		if historial[i].Estado != EstadoAprobado {
			return false
		}
	}
	return true
}
