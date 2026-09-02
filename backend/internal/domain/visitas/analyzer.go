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

	// ConfianzaPct resume todo lo anterior en un 0-100 auditable. Es contra
	// esto que se decide el autopase, en vez del contador de aprobaciones
	// consecutivas que se configuraba antes (ver score.go).
	ConfianzaPct    int
	Factores        []FactorScore
	Recomendaciones []string
}

// ScoreIA es el subconjunto serializable de ScoreContexto que se persiste y
// expone al dashboard — sin CambioModalidad (nunca se calcula, siempre
// false, exponerlo mentiría "sin cambios") ni ResumenTexto (va en su propia
// columna resumen_ia, no duplicado dentro del score).
type ScoreIA struct {
	ConfianzaPct      int           `json:"confianza_pct"`
	NivelConfianza    string        `json:"nivel_confianza"`
	Factores          []FactorScore `json:"factores,omitempty"`
	Recomendaciones   []string      `json:"recomendaciones,omitempty"`
	VecesVisitado     int           `json:"veces_visitado"`
	UltimaVisita      *time.Time    `json:"ultima_visita,omitempty"`
	AnomaliaMatricula bool          `json:"anomalia_matricula"`
	HorarioInusual    bool          `json:"horario_inusual"`
	RechazadoPrevio   bool          `json:"rechazado_previo"`
	OCRSospechoso     bool          `json:"ocr_sospechoso"`
	Confiable         bool          `json:"confiable"`
	// GeneradoPorIA distingue el resumen narrativo del LLM del heurístico
	// determinista de respaldo (resumenHeuristicoDe) -- sin esto, kiosko,
	// kigo-app y el dashboard no tenían forma de avisar "análisis
	// automático, el asistente de IA no está disponible" en vez de
	// presentar el heurístico como si fuera el análisis del LLM.
	GeneradoPorIA bool `json:"generado_por_ia"`
}

// clavesSeguraParaResidente son los factores que describen solo ESTA
// visita -- nunca comparan contra el historial del visitante en el resto
// del tenant. El resto (recurrencia, racha_limpia, rechazo_previo,
// placa_distinta/coincide, horario_inusual, cambio_modalidad) se calculan
// contra visitas del mismo visitante en CUALQUIER casa del fraccionamiento
// (ver historialPrevio en informativo.go/handlers.go): mostrárselos a un
// residente filtraría, por ejemplo, que ese visitante fue rechazado en
// otra casa. Ver FiltrarScoreParaResidente.
var clavesSeguraParaResidente = map[string]bool{
	"primera_visita":       true,
	"identidad_vinculada":  true,
	"match_rostro":         true,
	"match_pin":            true,
	"match_qr":             true,
	"curp_invalida":        true,
	"curp_valida":          true,
	"sin_rostro":           true,
	"rostro_identificable": true,
	"rostro_capturado":     true,
	"sin_placa":            true,
	"sin_documento":        true,
	"documento_borroso":    true,
	"documento_nitido":     true,
}

// FiltrarScoreParaResidente regresa una copia de ScoreIA con solo lo que es
// seguro mostrarle a un residente: el número y nivel de confianza, y los
// factores de la lista blanca de arriba. Recomendaciones se descarta
// completo (puede mencionar en texto libre un rechazo previo) y los campos
// sueltos que resumen el historial cross-casa (VecesVisitado, UltimaVisita,
// RechazadoPrevio, AnomaliaMatricula, HorarioInusual) se quedan en su
// zero-value en vez de copiarse.
func FiltrarScoreParaResidente(s *ScoreIA) *ScoreIA {
	if s == nil {
		return nil
	}
	factoresSeguros := make([]FactorScore, 0, len(s.Factores))
	for _, f := range s.Factores {
		if clavesSeguraParaResidente[f.Clave] {
			factoresSeguros = append(factoresSeguros, f)
		}
	}
	return &ScoreIA{
		ConfianzaPct:   s.ConfianzaPct,
		NivelConfianza: s.NivelConfianza,
		Factores:       factoresSeguros,
		GeneradoPorIA:  s.GeneradoPorIA,
	}
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

// resumenHeuristicoDe es el respaldo cuando el LLM no esta configurado o no
// devolvio algo utilizable. Antepone a GenerarResumenHeuristico los datos
// concretos de la visita, que el score no lleva: sin ellos todos los resumenes
// de respaldo salian identicos entre si y no le decian al guardia ni quien
// llego ni a donde iba.
func resumenHeuristicoDe(s ScoreContexto, v Visita) string {
	var partes []string

	nombre := strings.TrimSpace(v.Titular)
	casa := strings.TrimSpace(v.CasaDestino)
	switch {
	case nombre != "" && casa != "":
		partes = append(partes, fmt.Sprintf("%s va a %s.", nombre, casa))
	case nombre != "":
		partes = append(partes, nombre+".")
	case casa != "":
		partes = append(partes, "Visita con destino "+casa+".")
	}

	if placa := strings.TrimSpace(v.Placa); placa != "" {
		partes = append(partes, "Vehiculo "+placa+".")
	}

	partes = append(partes, s.AScoreIA().GenerarResumenHeuristico())

	// Sin LLM, el nivel de confianza es lo único que le resume al guardia todo
	// el análisis de un vistazo; los factores que lo componen los pinta el
	// dashboard aparte.
	if s.ConfianzaPct > 0 {
		partes = append(partes, fmt.Sprintf("Confianza %s (%d/100).", s.NivelConfianza(), s.ConfianzaPct))
	}
	return strings.Join(partes, " ")
}

// AScoreIA convierte el resultado interno del análisis al subconjunto que
// se persiste y se expone al dashboard.
func (sc ScoreContexto) AScoreIA() ScoreIA {
	return ScoreIA{
		ConfianzaPct:      sc.ConfianzaPct,
		NivelConfianza:    sc.NivelConfianza(),
		Factores:          sc.Factores,
		Recomendaciones:   sc.Recomendaciones,
		VecesVisitado:     sc.VecesVisitado,
		UltimaVisita:      sc.UltimaVisita,
		AnomaliaMatricula: sc.AnomaliaMatricula,
		HorarioInusual:    sc.HorarioInusual,
		RechazadoPrevio:   sc.RechazadoPrevio,
		OCRSospechoso:     sc.OCRSospechoso,
		Confiable:         sc.Confiable,
	}
}

// AnalizarVisita compara la visita nueva contra el historial y devuelve el
// ScoreContexto, ya con el score de confianza y sus factores calculados.
// historial debe estar ordenado de más reciente a más antiguo.
//
// Ya no recibe un umbral: el número de aprobaciones consecutivas dejó de ser
// configurable y pasó a ser uno de los factores del score (rachaLimpiaMinima).
// Lo que el admin configura ahora es el porcentaje de confianza que exige para
// autopase, que es la misma decisión expresada en algo que se entiende.
//
// fuentes dice qué evidencia cuenta para el análisis (ver ScoreIaFuentes) --
// historial ya viene resuelto según esas mismas fuentes (ver
// Repository.HistorialDeVisitante), así que aquí solo hace falta acotar la
// comparación de placa, que es el único factor con un cálculo propio.
func AnalizarVisita(historial []Visita, nueva Visita, esperada EvidenciaEsperada, fuentes ScoreIaFuentes) ScoreContexto {
	sc := ScoreContexto{
		VecesVisitado: len(historial),
		OCRSospechoso: validarOCR(nueva.Curp),
	}

	if len(historial) == 0 {
		evaluarEntrada(&sc, nueva, historial, esperada, fuentes)
		return sc
	}

	ultima := historial[0].CreatedAt
	sc.UltimaVisita = &ultima

	// Si la visita no trae CURP, el historial vino agrupado por placa y todas las
	// matrículas son la misma por construcción: comparar no diría nada (ADR-0024).
	if fuentes.Placa && nueva.Placa != "" && nueva.Curp != "" {
		sc.AnomaliaMatricula = placaDiferente(historial, nueva.Placa)
	}

	for _, v := range historial {
		if v.Estado == EstadoRechazado {
			sc.RechazadoPrevio = true
			break
		}
	}

	sc.HorarioInusual = horarioInusual(historial, nueva.CreatedAt)

	evaluarEntrada(&sc, nueva, historial, esperada, fuentes)

	// Confiable se conserva porque el dashboard ya pintaba una insignia con
	// él, pero ahora deriva del score en vez de un contador suelto.
	sc.Confiable = !sc.Bloqueantes() && sc.NivelConfianza() == "alta"

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
