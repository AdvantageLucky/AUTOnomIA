package visitas

import (
	"context"
	"fmt"
	"log"
	"regexp"
	"strings"
	"time"

	"kigo-autonomia-backend/internal/platform/llmclient"
)

// zonaMX se usa para formatear cualquier hora que se le muestre a un humano
// (guardia, admin) o se le describa a un LLM. El servidor corre en un
// contenedor con reloj en UTC (confirmado: sin TZ configurada) y GORM/pgx
// devuelve los time.Time de TIMESTAMPTZ en esa misma zona -- sin convertir
// antes de formatear, "Hora de llegada: 04:34" en el prompt describía una
// entrada de las 22:34 en México, 6 horas adelantada de la hora real. Un
// LLM al que se le da una hora incorrecta como dato "correcto" no está
// alucinando, solo repite fielmente un dato de entrada que ya venía mal.
var zonaMX = func() *time.Location {
	loc, err := time.LoadLocation("America/Mexico_City")
	if err != nil {
		log.Printf("[visitas] no se pudo cargar America/Mexico_City, usando UTC: %v", err)
		return time.UTC
	}
	return loc
}()

const systemPromptVisitas = "Eres un analista de seguridad en caseta residencial. Escribes en español, para el guardia, explicando qué pasó en UNA entrada concreta y qué conviene revisar de ella. Usas únicamente los datos que se te dan: nunca inventas cifras ni antecedentes, nunca escribes campos vacíos entre corchetes, y nunca opinas sobre el residencial, su administración ni sus procedimientos. Dices cada cosa una sola vez."

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
	if len(s.Factores) == 0 {
		// Sin config de kiosko a la mano en esta función, se asume el
		// comportamiento de siempre (las 3 fuentes prendidas) -- este
		// recálculo es solo un respaldo para cuando el score llegó sin
		// factores, no la vía normal en la que sí se conoce la config.
		evaluarEntrada(&s, v, nil, EvidenciaEsperada{}, ScoreIaFuentes{Documento: true, Placa: true, Rostro: true})
	}

	if strings.TrimSpace(llmURL) == "" {
		return resumenHeuristicoDe(s, v), nil
	}

	// 260 tokens y no los 120 por defecto: el análisis son dos párrafos y con
	// el techo viejo se cortaba a media frase del segundo. Tampoco los 360 que
	// se pusieron primero — sobraba tanto margen que el modelo lo llenaba
	// repitiéndose en vez de terminar.
	resumen, err := llmclient.CompletarConLimite(ctx, strings.TrimSpace(llmURL), systemPromptVisitas, construirPrompt(s, v), 260)
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

// reOracion parte el texto en oraciones conservando el signo final.
var reOracion = regexp.MustCompile(`[^.!?]+[.!?]*`)

// reNoAlfanum se usa para normalizar una oración antes de compararla: dos
// frases que solo difieren en espacios o puntuación son la misma repetición.
var reNoAlfanum = regexp.MustCompile(`[^\p{L}\p{N}]+`)

// resumenUtilizable rechaza lo que no se le puede enseñar al guardia: vacío, o
// con huecos sin rellenar. No intenta parchear el texto quitando los corchetes
// — la frase resultante quedaría coja ("llegó a la casa .") y sonaría a error.
//
// Sí recorta las repeticiones, que son otra cosa: el texto hasta el bucle es
// bueno y solo sobra lo que viene después.
func resumenUtilizable(resumen string) (string, bool) {
	limpio := strings.TrimSpace(resumen)
	if limpio == "" {
		return "", false
	}
	if rePlaceholder.MatchString(limpio) {
		return "", false
	}

	limpio = recortarRepeticiones(limpio)
	// Si tras recortar no queda ni una frase de largo razonable, el modelo no
	// llegó a decir nada: mejor el heurístico.
	if len([]rune(limpio)) < 40 {
		return "", false
	}
	return limpio, true
}

// recortarRepeticiones corta el texto en cuanto una oración se repite.
//
// Un modelo local chico, con margen de tokens y sin corte por línea en blanco,
// entra en bucle y repite la misma frase hasta agotar el presupuesto. La
// penalización de repetición del sampler lo hace menos probable pero no lo
// garantiza, y el bucle es justo lo que no se le puede enseñar a un guardia.
func recortarRepeticiones(texto string) string {
	vistas := map[string]bool{}
	var parrafos []string

	for _, parrafo := range strings.Split(texto, "\n\n") {
		var oraciones []string
		for _, o := range reOracion.FindAllString(parrafo, -1) {
			oracion := strings.TrimSpace(o)
			if oracion == "" {
				continue
			}
			clave := strings.ToLower(reNoAlfanum.ReplaceAllString(oracion, " "))
			clave = strings.TrimSpace(clave)
			// Las frases muy cortas ("Sin anomalías.") pueden repetirse de
			// forma legítima entre párrafos; el bucle son frases largas.
			if len([]rune(clave)) > 25 {
				if vistas[clave] {
					return strings.TrimSpace(strings.Join(append(parrafos, strings.Join(oraciones, " ")), "\n\n"))
				}
				vistas[clave] = true
			}
			oraciones = append(oraciones, oracion)
		}
		if len(oraciones) > 0 {
			parrafos = append(parrafos, strings.Join(oraciones, " "))
		}
	}

	return strings.TrimSpace(strings.Join(parrafos, "\n\n"))
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
	if motivo := strings.TrimSpace(v.Motivo); motivo != "" {
		datos = append(datos, "Motivo: "+motivo)
	}
	if placa := strings.TrimSpace(v.Placa); placa != "" {
		datos = append(datos, "Placa: "+placa)
	} else {
		datos = append(datos, "Llega a pie (sin placa registrada)")
	}
	if !v.CreatedAt.IsZero() {
		datos = append(datos, "Hora de llegada: "+v.CreatedAt.In(zonaMX).Format("15:04"))
	}

	if s.VecesVisitado == 0 {
		datos = append(datos, "Historial: es su primera visita registrada")
	} else {
		historial := fmt.Sprintf("Historial: ha entrado %d vez", s.VecesVisitado)
		if s.VecesVisitado != 1 {
			historial = fmt.Sprintf("Historial: ha entrado %d veces", s.VecesVisitado)
		}
		if s.UltimaVisita != nil {
			historial += ", la última el " + s.UltimaVisita.In(zonaMX).Format("02/01/2006")
		}
		datos = append(datos, historial)
	}

	positivos, negativos, faltantes := s.DescripcionFactores()

	secciones := []string{
		"### Datos de la visita\n" + strings.Join(datos, "\n"),
		fmt.Sprintf("### Score de confianza\n%d de 100 (confianza %s), calculado a partir de los puntos siguientes.",
			s.ConfianzaPct, s.NivelConfianza()),
	}
	secciones = append(secciones, bloque("A favor", positivos, "Nada a favor por ahora."))
	secciones = append(secciones, bloque("En contra", negativos, "Ninguna anomalía detectada."))
	secciones = append(secciones, bloque("Evidencia que falta", faltantes, "No falta evidencia."))

	return fmt.Sprintf(`### Instrucción
Escribe para el guardia de caseta un análisis de esta entrada, en español, en 4 a 6 oraciones repartidas en dos párrafos.

Párrafo 1 — qué pasó: quién llegó, a dónde va, cómo se identificó y qué dice su historial.
Párrafo 2 — qué mirar: si hay puntos en contra o evidencia faltante, explícalos y di por qué importan. Si no hay ninguno, dilo en una frase.

Reglas:
- Usa solo los datos de abajo. No inventes nada, ni cifras ni antecedentes.
- Si un dato no aparece, no lo menciones. NUNCA escribas corchetes, llaves ni campos vacíos como [nombre] o [casa].
- Menciona el score una sola vez y en palabras ("confianza alta", "confianza baja"), no repitas el número.
- No copies la lista tal cual: explícala con tus palabras y conecta los puntos entre sí.
- No repitas ninguna frase. Di cada cosa una sola vez y termina.
- Escribes SOBRE ESTA ENTRADA, no sobre el residencial. No juzgues ni comentes
  al residencial, a su administración, a sus guardias, a sus procedimientos ni
  a sus autoridades. Nada de frases como "falta coordinación" o "el control es
  deficiente": no tienes datos para afirmar eso y no es lo que se te pregunta.
- No especules sobre intenciones ni sobre lo que pudo haber pasado. Si un dato
  falta, di que falta; no imagines por qué.
- Nada de saludos, encabezados, viñetas ni despedidas: solo los dos párrafos.

%s

### Análisis
`, strings.Join(secciones, "\n\n"))
}

// bloque arma una sección del prompt, con un texto explícito cuando la lista
// viene vacía: dejar la sección en blanco invita al modelo a rellenarla por su
// cuenta, que es justo lo que se quiere evitar.
func bloque(titulo string, lineas []string, siVacio string) string {
	if len(lineas) == 0 {
		return "### " + titulo + "\n" + siVacio
	}
	return "### " + titulo + "\n- " + strings.Join(lineas, "\n- ")
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

	var porTipo []string
	for _, tipo := range []string{"RESIDENTE", "INVITADO", "VISITANTE"} {
		if n := d.PorTipo[tipo]; n > 0 {
			porTipo = append(porTipo, fmt.Sprintf("%s: %d", tipo, n))
		}
	}
	porTipoTxt := "Sin desglose disponible."
	if len(porTipo) > 0 {
		porTipoTxt = strings.Join(porTipo, ", ")
	}

	destacadasTxt := "Ninguna rechazada ni en revisión en el período."
	if len(d.Destacadas) > 0 {
		var lineas []string
		for _, vd := range d.Destacadas {
			lineas = append(lineas, fmt.Sprintf("- %s a las %s, destino %s (%s)",
				vd.Titular, vd.Hora, vd.CasaDestino, vd.Estado))
		}
		destacadasTxt = strings.Join(lineas, "\n")
	}

	prompt := fmt.Sprintf(`### Instrucción
Escribe para el administrador un resumen de 2 o 3 oraciones sobre la actividad de las últimas 12 horas, en español.

Reglas:
- Usa solo los datos de abajo. No inventes nombres, horas ni motivos que no aparezcan aquí.
- NUNCA escribas corchetes, llaves ni campos vacíos como [dato].
- Menciona el total y destaca lo que merezca atención (rechazos, revisiones pendientes) -- si hay entradas destacadas, puedes nombrarlas brevemente.
- Si no hubo nada inusual, dilo en una frase y no alargues.

### Actividad del período
Visitas totales: %d
Aprobadas: %d
Rechazadas: %d
En revisión: %d
Marcadas para revisión de IA: %d
Por tipo de visitante: %s

### Entradas rechazadas o en revisión
%s

### Resumen
`, d.TotalVisitas, d.Aprobadas, d.Rechazadas, d.EnRevision, d.Intervenidas, porTipoTxt, destacadasTxt)

	resumen, err := llmclient.Completar(ctx, strings.TrimSpace(llmURL), systemPromptReporte, prompt)
	if err != nil {
		return resumirDatosTexto(d), err
	}
	if limpio, ok := resumenUtilizable(resumen); ok {
		return limpio, nil
	}
	return resumirDatosTexto(d), fmt.Errorf("el LLM respondió vacío o con placeholders sin rellenar")
}
