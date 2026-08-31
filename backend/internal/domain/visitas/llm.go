package visitas

import (
	"context"
	"fmt"
	"regexp"
	"strings"

	"kigo-autonomia-backend/internal/platform/llmclient"
)

const systemPromptVisitas = "Eres un asistente de seguridad en caseta residencial. Escribes resúmenes breves y concretos en español para el guardia, usando únicamente los datos que se te dan. Nunca inventas datos ni escribes campos vacíos entre corchetes."

// rePlaceholder detecta los huecos que deja un modelo cuando le falta un dato:
// "[nombre]", "[Nombre del visitante]", "{nombre}", "<nombre>". Es el sintoma
// exacto que se veia en el dashboard, porque el prompt viejo pedia un resumen
// "sobre este visitante" sin pasarle jamas su nombre.
var rePlaceholder = regexp.MustCompile(`\[[^\]]*\]|\{[^}]*\}|<[^>]*>`)

// GenerarResumen convierte una visita y su ScoreContexto en texto narrativo en
// español. Primero intenta consultar el servidor LLM (soporta endpoints
// /completion y /v1/chat/completions). Si el LLM está apagado, falla o devuelve
// un texto inservible, cae al resumen heurístico — el texto siempre es
// utilizable, pero el error no-nil le avisa al caller que la llamada al LLM
// falló de verdad (a diferencia de "no había LLM configurado", que no es error).
func GenerarResumen(ctx context.Context, llmURL string, s ScoreContexto, v Visita) (string, error) {
	if strings.TrimSpace(llmURL) == "" {
		return resumenHeuristicoDe(s, v), nil
	}

	resumen, err := llmclient.Completar(ctx, strings.TrimSpace(llmURL), systemPromptVisitas, construirPrompt(s, v))
	if err != nil {
		return resumenHeuristicoDe(s, v), err
	}
	if limpio, ok := resumenUtilizable(resumen); ok {
		return limpio, nil
	}
	// Un modelo local chico ignora las instrucciones cada tanto. El heuristico
	// dice menos, pero nunca dice algo que no sea cierto -- preferible a
	// publicarle al guardia un "[nombre] llego a [casa]".
	return resumenHeuristicoDe(s, v), fmt.Errorf("el LLM respondió vacío o con placeholders sin rellenar")
}

// resumenUtilizable rechaza lo que no se le puede enseñar al guardia: vacío, o
// con huecos sin rellenar. No intenta parchear el texto quitando los corchetes
// — la frase resultante quedaría coja ("llegó a la casa .") y sonaría a error.
func resumenUtilizable(resumen string) (string, bool) {
	limpio := strings.TrimSpace(resumen)
	if limpio == "" {
		return "", false
	}
	if rePlaceholder.MatchString(limpio) {
		return "", false
	}
	return limpio, true
}

// construirPrompt le da al modelo los datos reales de la visita. Antes solo
// recibia el conteo de visitas y las banderas de anomalia, asi que no tenia
// con que escribir nada especifico y todos los resumenes salian
// intercambiables entre si.
func construirPrompt(s ScoreContexto, v Visita) string {
	var datos []string

	if nombre := strings.TrimSpace(v.Titular); nombre != "" {
		datos = append(datos, "Nombre: "+nombre)
	}
	if v.TipoVisitante != "" {
		datos = append(datos, "Tipo: "+string(v.TipoVisitante))
	}
	if casa := strings.TrimSpace(v.CasaDestino); casa != "" {
		datos = append(datos, "Va a: "+casa)
	}
	if placa := strings.TrimSpace(v.Placa); placa != "" {
		datos = append(datos, "Placa: "+placa)
	} else {
		datos = append(datos, "Llega a pie (sin placa registrada)")
	}
	if !v.CreatedAt.IsZero() {
		datos = append(datos, "Hora de llegada: "+v.CreatedAt.Format("15:04"))
	}

	if s.VecesVisitado == 0 {
		datos = append(datos, "Historial: es su primera visita registrada")
	} else {
		historial := fmt.Sprintf("Historial: ha entrado %d vez", s.VecesVisitado)
		if s.VecesVisitado != 1 {
			historial = fmt.Sprintf("Historial: ha entrado %d veces", s.VecesVisitado)
		}
		if s.UltimaVisita != nil {
			historial += ", la última el " + s.UltimaVisita.Format("02/01/2006")
		}
		datos = append(datos, historial)
	}
	if s.Confiable {
		datos = append(datos, "Marcado como visitante de confianza (varias entradas seguidas aprobadas sin incidencias)")
	}

	anomalias := descripcionAnomalias(s)
	if len(anomalias) > 0 {
		datos = append(datos, "Anomalías detectadas: "+strings.Join(anomalias, "; "))
	} else {
		datos = append(datos, "Anomalías detectadas: ninguna")
	}

	return fmt.Sprintf(`### Instrucción
Escribe para el guardia de caseta un resumen de 2 o 3 oraciones sobre esta visita, en español.

Reglas:
- Usa solo los datos de abajo. No inventes nada.
- Si un dato no aparece, no lo menciones. NUNCA escribas corchetes, llaves ni campos vacíos como [nombre] o [casa].
- Empieza por quién es y a dónde va.
- Si hay anomalías, dilas explícitamente y di qué debería revisar el guardia.
- Si no hay anomalías y el visitante es recurrente, dilo en una frase y no alargues.
- Nada de saludos, encabezados ni despedidas: solo el resumen.

### Datos de la visita
%s

### Resumen
`, strings.Join(datos, "\n"))
}

func descripcionAnomalias(s ScoreContexto) []string {
	var anomalias []string
	if s.AnomaliaMatricula {
		anomalias = append(anomalias, "llega con una placa distinta a la de sus visitas anteriores")
	}
	if s.CambioModalidad {
		anomalias = append(anomalias, "solía venir con invitación QR y esta vez llegó sin ella")
	}
	if s.HorarioInusual {
		anomalias = append(anomalias, "el horario de llegada es inusual para este visitante")
	}
	if s.RechazadoPrevio {
		anomalias = append(anomalias, "tiene un rechazo previo registrado")
	}
	if s.OCRSospechoso {
		anomalias = append(anomalias, "la CURP no pasa validación de formato (posible error de lectura del INE)")
	}
	return anomalias
}

const systemPromptReporte = "Eres un analista de seguridad residencial. Resumes la actividad de un turno en español, con cifras concretas y sin inventar datos."

// GenerarResumenPeriodo redacta el reporte de turno. Antes esto reusaba
// GenerarResumen con un ScoreContexto inventado (solo VecesVisitado), asi que
// al modelo se le pedia un resumen "de este visitante" con cifras de periodo y
// salia algo que no describia ni una cosa ni la otra.
func GenerarResumenPeriodo(ctx context.Context, llmURL string, d datosAgregados) (string, error) {
	if strings.TrimSpace(llmURL) == "" {
		return resumirDatosTexto(d), nil
	}

	prompt := fmt.Sprintf(`### Instrucción
Escribe para el administrador un resumen de 2 o 3 oraciones sobre la actividad de las últimas 12 horas, en español.

Reglas:
- Usa solo las cifras de abajo. No inventes nada.
- NUNCA escribas corchetes, llaves ni campos vacíos como [dato].
- Menciona el total y destaca lo que merezca atención (rechazos, revisiones pendientes).
- Si no hubo nada inusual, dilo en una frase y no alargues.

### Actividad del período
Visitas totales: %d
Aprobadas: %d
Rechazadas: %d
En revisión: %d

### Resumen
`, d.TotalVisitas, d.Aprobadas, d.Rechazadas, d.EnRevision)

	resumen, err := llmclient.Completar(ctx, strings.TrimSpace(llmURL), systemPromptReporte, prompt)
	if err != nil {
		return resumirDatosTexto(d), err
	}
	if limpio, ok := resumenUtilizable(resumen); ok {
		return limpio, nil
	}
	return resumirDatosTexto(d), fmt.Errorf("el LLM respondió vacío o con placeholders sin rellenar")
}
