package visitas

import (
	"fmt"

	"kigo-autonomia-backend/internal/domain/kiosko"
)

// El score de confianza es un porcentaje 0-100 que resume, en un solo numero,
// todo lo que sabemos de una entrada. Existe para que el autopase se configure
// como "aprueba solo si la confianza llega a X%" en vez del contador de
// aprobaciones consecutivas que habia antes: un contador no dice nada de la
// calidad de la evidencia ni de las anomalias, solo de la racha.
//
// El calculo es deliberadamente explicable: cada factor suma o resta un peso
// fijo y se conserva en Factores, para que el dashboard pueda mostrar de donde
// salio el numero. Un score que el guardia no puede auditar no le sirve para
// decidir.
const (
	// Punto de partida de un desconocido sin antecedentes: ni confiable ni
	// sospechoso.
	scoreBase = 50

	// Cuantas de las ultimas visitas deben estar aprobadas para considerar
	// que la racha esta limpia.
	rachaLimpiaMinima = 3

	// Tope de recurrencia: a partir de aqui, mas visitas ya no suman.
	visitasParaTopeRecurrencia = 8
	puntosPorVisita            = 3
)

// TipoFactor clasifica cada aspecto evaluado para que el dashboard lo pinte
// distinto sin tener que interpretar el signo del impacto.
type TipoFactor string

const (
	FactorPositivo TipoFactor = "positivo"
	FactorNegativo TipoFactor = "negativo"
	// FactorFaltante es evidencia que no se capturo. No es una anomalia (nadie
	// hizo nada malo), pero baja la confianza porque hay menos con que
	// verificar, y es lo que el guardia puede ir a pedir.
	FactorFaltante TipoFactor = "faltante"
)

// EvidenciaEsperada dice que capturas exigia la config del kiosko para esta
// entrada. Sin esto el score castigaria a un acceso vehicular por no traer INE
// cuando su configuracion nunca la pidio, y ningun visitante recurrente de una
// caseta vehicular llegaria jamas al umbral de autopase.
//
// El cero value ("no se esperaba nada") es el correcto para un analisis sin
// config a la mano: no se penaliza lo que nadie pidio.
type EvidenciaEsperada struct {
	Rostro    bool
	Documento bool
	Placa     bool
}

// ScoreIaFuentes dice qué evidencia, ya capturada, cuenta para ligar esta
// visita con su historial (identidad para recurrencia/anomalías) y para los
// factores de comparación entre visitas. No es lo mismo que EvidenciaEsperada:
// esa dice qué se PIDIÓ capturar, esta dice qué SE USA en el análisis una vez
// capturado.
//
// Los 3 prendidos es el comportamiento de siempre. El admin apaga uno cuando
// el dato de prueba no es único por persona durante una demo (mismo vehículo,
// mismo rostro o CURP de prueba reutilizado entre varios actores) y el
// análisis lo leería como "el mismo visitante recurrente" sin serlo.
type ScoreIaFuentes struct {
	Documento bool
	Placa     bool
	Rostro    bool
}

// scoreIaFuentesDe traduce la config del kiosko a ScoreIaFuentes. Sin config
// a la mano (análisis fuera de un kiosko concreto), los 3 quedan prendidos:
// es el comportamiento de siempre.
func scoreIaFuentesDe(cfg *kiosko.KioskoConfig) ScoreIaFuentes {
	if cfg == nil {
		return ScoreIaFuentes{Documento: true, Placa: true, Rostro: true}
	}
	return ScoreIaFuentes{
		Documento: cfg.UsarDocumentoEnScoreIA,
		Placa:     cfg.UsarPlacaEnScoreIA,
		Rostro:    cfg.UsarRostroEnScoreIA,
	}
}

// FactorScore es un aspecto evaluado de la entrada con su peso en el score.
type FactorScore struct {
	Clave    string     `json:"clave"`
	Etiqueta string     `json:"etiqueta"`
	Detalle  string     `json:"detalle,omitempty"`
	Impacto  int        `json:"impacto"`
	Tipo     TipoFactor `json:"tipo"`
}

// evaluarEntrada recorre todos los aspectos de la visita y devuelve el score,
// los factores que lo componen y que hacer al respecto.
//
// historialCompleto y propio ya vienen sin la visita actual y ordenados de
// mas reciente a mas antiguo (ver AnalizarVisita). historialCompleto es
// cross-casa (cualquier destino del fraccionamiento) y solo se usa para
// cambio_modalidad, que necesita saber si esta identidad fue alguna vez
// residente/invitada en CUALQUIER lado; propio ya viene acotado al mismo
// destino de v y es lo que alimenta racha_limpia -- sc.VecesVisitado
// (usado por el factor "recurrencia") ya se calculo sobre propio en
// AnalizarVisita, antes de llamar aqui.
func evaluarEntrada(sc *ScoreContexto, v Visita, historialCompleto []Visita, propio []Visita, esperada EvidenciaEsperada, fuentes ScoreIaFuentes) {
	var factores []FactorScore
	suma := scoreBase

	add := func(clave, etiqueta, detalle string, impacto int, tipo TipoFactor) {
		factores = append(factores, FactorScore{
			Clave: clave, Etiqueta: etiqueta, Detalle: detalle, Impacto: impacto, Tipo: tipo,
		})
		suma += impacto
	}

	// ── Historial ────────────────────────────────────────────────────────────
	switch {
	case sc.VecesVisitado == 0:
		add("primera_visita", "Primera visita registrada",
			"No hay historial contra el cual comparar.", -5, FactorFaltante)
	default:
		visitasContadas := sc.VecesVisitado
		if visitasContadas > visitasParaTopeRecurrencia {
			visitasContadas = visitasParaTopeRecurrencia
		}
		detalle := fmt.Sprintf("%d entradas previas registradas.", sc.VecesVisitado)
		if sc.UltimaVisita != nil {
			detalle = fmt.Sprintf("%d entradas previas, la ultima el %s.",
				sc.VecesVisitado, sc.UltimaVisita.In(zonaMX).Format("02/01/2006"))
		}
		add("recurrencia", "Visitante recurrente", detalle, visitasContadas*puntosPorVisita, FactorPositivo)
	}

	if rachaLimpia(propio) {
		add("racha_limpia", "Racha de entradas aprobadas",
			fmt.Sprintf("Sus ultimas %d entradas fueron aprobadas sin incidencias.", rachaLimpiaMinima),
			12, FactorPositivo)
	}

	if sc.RechazadoPrevio {
		add("rechazo_previo", "Rechazo previo registrado",
			"Al menos una de sus entradas anteriores fue rechazada.", -35, FactorNegativo)
	}

	// ── Identidad ────────────────────────────────────────────────────────────
	if v.PersonaID != nil {
		add("identidad_vinculada", "Identidad vinculada a un registro",
			"La entrada quedo ligada a una persona ya dada de alta en el sistema.", 12, FactorPositivo)
	}

	switch v.TipoDocumento {
	case DocumentoRostro:
		// Este es el caso en que el kiosko comparo el rostro en vivo contra los
		// embeddings guardados y encontro coincidencia por encima del umbral.
		add("match_rostro", "Rostro reconocido",
			"El rostro coincidio con un registro biometrico existente.", 15, FactorPositivo)
	case DocumentoPIN:
		add("match_pin", "Acceso por PIN",
			"Se identifico con su PIN de residente.", 8, FactorPositivo)
	case DocumentoQR:
		add("match_qr", "Invitacion QR valida",
			"Presento un QR firmado y vigente.", 10, FactorPositivo)
	}

	switch {
	case sc.OCRSospechoso:
		add("curp_invalida", "CURP con formato invalido",
			"La CURP leida del documento no pasa validacion estructural: posible error de OCR.", -18, FactorNegativo)
	case v.Curp != "":
		add("curp_valida", "CURP valida", "La CURP leida pasa validacion de formato.", 8, FactorPositivo)
	}

	// ── Evidencia capturada ──────────────────────────────────────────────────
	// Solo se marca como faltante lo que la config del kiosko si pedia.
	if v.FotoRostroURL == "" {
		if esperada.Rostro {
			add("sin_rostro", "Falta la foto de rostro",
				"El kiosko la pedia y no quedo registrada: no hay con que verificar quien entro.", -12, FactorFaltante)
		}
	} else if len(v.EmbeddingRostro) > 0 {
		// Con huella facial guardada, este rostro es comparable contra las
		// entradas anteriores: es lo que convierte a un flujo de solo rostro +
		// destino en algo donde alguien puede llegar a ser recurrente.
		add("rostro_identificable", "Rostro registrado y comparable",
			"Se guardo la huella facial de esta entrada, asi que sirve para reconocerlo despues.",
			8, FactorPositivo)
	} else {
		add("rostro_capturado", "Rostro capturado",
			"Hay foto, pero sin huella facial no se puede comparar contra entradas anteriores.",
			4, FactorPositivo)
	}
	if esperada.Placa && v.Placa == "" {
		add("sin_placa", "Falta la placa",
			"El kiosko la pedia y no quedo registrada.", -8, FactorFaltante)
	}
	if v.FotoDocumentoURL == "" {
		if esperada.Documento {
			add("sin_documento", "Falta la identificacion",
				"El kiosko la pedia y no quedo registrada.", -8, FactorFaltante)
		}
	} else if v.CalidadIne != "" && v.CalidadIne != "nitida" {
		add("documento_borroso", "Identificacion poco nitida",
			"La foto del documento quedo por debajo del umbral de nitidez.", -6, FactorNegativo)
	} else if v.CalidadIne == "nitida" {
		add("documento_nitido", "Identificacion nitida", "", 6, FactorPositivo)
	}

	// ── Vehiculo ─────────────────────────────────────────────────────────────
	// Si el admin apagó la placa como fuente del score (demo con un mismo
	// vehículo de prueba en varias personas, por ejemplo), esto no se evalúa:
	// sc.AnomaliaMatricula ya viene en false porque AnalizarVisita tampoco la
	// calculó.
	if fuentes.Placa {
		switch {
		case sc.AnomaliaMatricula:
			add("placa_distinta", "Placa distinta a la habitual",
				fmt.Sprintf("Llega con %s, que no coincide con la placa de sus visitas anteriores.", v.Placa),
				-22, FactorNegativo)
		case v.Placa != "" && sc.VecesVisitado > 0:
			add("placa_coincide", "Placa coincide con la habitual",
				fmt.Sprintf("%s es la misma de sus entradas anteriores.", v.Placa), 8, FactorPositivo)
		}
	}

	// ── Contexto ─────────────────────────────────────────────────────────────
	if sc.HorarioInusual {
		add("horario_inusual", "Horario inusual",
			fmt.Sprintf("Llega a las %s, fuera de su franja habitual.", v.CreatedAt.In(zonaMX).Format("15:04")),
			-12, FactorNegativo)
	}
	// Cambio de modalidad: no es "cambió de tipo" en general (un residente
	// puede entrar un día por PIN y otro por rostro, ninguno de los dos es
	// una bajada) -- es específicamente que esta misma identidad ya
	// demostró estar vinculada a un residente o a una invitación válida, y
	// ahora decide entrar como visitante anónimo, el camino con menos
	// verificación de todos. historial ya viene unido por CURP + rostro
	// (ver Repository.HistorialDeVisitante), así que esto detecta al mismo
	// rostro que antes entró como residente aunque esta vez no traiga CURP
	// que lo ligue por ese lado.
	//
	// v.PersonaID != nil en este punto significa que RegisterVisita YA
	// cruzó esta entrada contra los residentes ACTIVOS del tenant
	// (BuscarPersonaPorIdentidad) y la encontró -- es decir, quien entra
	// sigue siendo residente en este momento, con acceso vigente. Eso NO es
	// una bajada de verificación real (la identidad se confirmó igual de
	// fuerte que un login por PIN/rostro, solo que por el flujo de
	// visitante), así que no debe bloquear el autopase ni restar como una
	// anomalía -- solo se anota como contexto informativo.
	//
	// Cuando v.PersonaID es nil, en cambio, quien entra NO es reconocido
	// como residente activo ahora mismo -- el único motivo por el que el
	// historial de esta identidad puede traer entradas RESIDENTE/CON
	// INVITACION sin que BuscarPersonaPorIdentidad la haya enlazado es que
	// ese acceso ya no está vigente (se le revocó la membresía, o la
	// invitación expiró y el residente que la dio ya no responde por él).
	// Eso sí es una bajada real de verificación y debe seguir bloqueando el
	// autopase como hasta ahora.
	if v.TipoVisitante == TipoSinInvitacion {
		var huboResidente, huboInvitado bool
		for _, h := range historialCompleto {
			switch h.TipoVisitante {
			case TipoResidente:
				huboResidente = true
			case TipoConInvitacion:
				huboInvitado = true
			}
		}
		if huboResidente || huboInvitado {
			procedencia := "con una invitación QR válida"
			switch {
			case huboResidente && huboInvitado:
				procedencia = "como residente y también con invitación QR"
			case huboResidente:
				procedencia = "como residente (PIN o reconocimiento facial)"
			}

			if v.PersonaID != nil {
				add("entrada_por_visitante_siendo_residente", "Entró como visitante, pero sigue siendo residente",
					fmt.Sprintf(
						"Esta identidad entró antes %s y esta vez usó el flujo de visitante sin invitación -- "+
							"el sistema la reconoció contra el padrón de residentes activos y le dio el mismo acceso "+
							"que por PIN o reconocimiento facial. No es una anomalía.",
						procedencia,
					), 5, FactorPositivo)
			} else {
				sc.CambioModalidad = true
				add("cambio_modalidad", "Cambio de modalidad",
					fmt.Sprintf(
						"Esta misma identidad ya entró antes %s, pero ese acceso ya no está vigente "+
							"(no se reconoce como residente activo ahora) y esta vez llegó como visitante sin invitación.",
						procedencia,
					), -10, FactorNegativo)
			}
		}
	}

	sc.Factores = factores
	sc.ConfianzaPct = acotar(suma, 0, 100)
	sc.Recomendaciones = construirRecomendaciones(sc, v)
}

// Bloqueantes returns true si hay algo que impide aprobar automaticamente por
// mucho score que tenga. Un rechazo previo o una placa que no cuadra son cosas
// que una persona tiene que mirar, no un umbral.
func (sc ScoreContexto) Bloqueantes() bool {
	return sc.RechazadoPrevio || sc.AnomaliaMatricula || sc.OCRSospechoso || sc.CambioModalidad
}

// PuedeAutoPass decide el autopase contra el umbral porcentual configurado.
func (sc ScoreContexto) PuedeAutoPass(umbralPct int) bool {
	return !sc.Bloqueantes() && sc.ConfianzaPct >= umbralPct
}

// construirRecomendaciones traduce los factores a lo que el guardia deberia
// hacer. Es lo que el resumen de texto no puede garantizar por si solo: el LLM
// puede omitirlas o inventarlas, estas salen de los mismos datos que el score.
func construirRecomendaciones(sc *ScoreContexto, v Visita) []string {
	var recs []string

	if sc.RechazadoPrevio {
		recs = append(recs, "Se recomienda revisar el motivo del rechazo anterior antes de autorizar.")
	}
	if sc.AnomaliaMatricula {
		recs = append(recs, "Se recomienda confirmar la placa con el conductor: no coincide con la de sus visitas previas.")
	}
	if sc.OCRSospechoso {
		recs = append(recs, "Se recomienda volver a capturar la identificacion: la CURP no pasa validacion de formato.")
	}
	if v.FotoRostroURL == "" {
		recs = append(recs, "Falta la foto de rostro: pedirla antes de dar acceso.")
	}
	if v.FotoDocumentoURL == "" {
		recs = append(recs, "Falta la identificacion: solicitar INE o documento equivalente.")
	}
	if v.CasaDestino == "" {
		recs = append(recs, "Falta la casa destino: preguntar a donde se dirige.")
	}
	if sc.HorarioInusual {
		recs = append(recs, "Se recomienda confirmar con el anfitrion: llega fuera de su horario habitual.")
	}
	if sc.VecesVisitado == 0 && !sc.Bloqueantes() {
		recs = append(recs, "Se recomienda confirmar con el anfitrion: es su primera visita registrada.")
	}

	if len(recs) == 0 {
		recs = append(recs, "Sin observaciones: la evidencia esta completa y no se detectaron anomalias.")
	}
	return recs
}

// rachaLimpia mira si las ultimas rachaLimpiaMinima entradas fueron aprobadas.
// Reemplaza al viejo esConfiable(historial, umbral), donde el umbral salia de
// la config: ese numero ahora se expresa como porcentaje de confianza, y la
// racha pasa a ser uno de los factores que lo alimentan.
func rachaLimpia(historial []Visita) bool {
	if len(historial) < rachaLimpiaMinima {
		return false
	}
	for i := range rachaLimpiaMinima {
		if historial[i].Estado != EstadoAprobado {
			return false
		}
	}
	return true
}

func acotar(v, min, max int) int {
	if v < min {
		return min
	}
	if v > max {
		return max
	}
	return v
}

// DescripcionFactores arma las lineas que se le pasan al LLM. Se separan por
// tipo para que el modelo distinga "esto es una alerta" de "esto falta".
func (sc ScoreContexto) DescripcionFactores() (positivos, negativos, faltantes []string) {
	for _, f := range sc.Factores {
		linea := f.Etiqueta
		if f.Detalle != "" {
			linea += " — " + f.Detalle
		}
		switch f.Tipo {
		case FactorPositivo:
			positivos = append(positivos, linea)
		case FactorNegativo:
			negativos = append(negativos, linea)
		case FactorFaltante:
			faltantes = append(faltantes, linea)
		}
	}
	return
}

// NivelConfianza etiqueta el score para que el dashboard y el resumen usen la
// misma escala y no digan cosas distintas del mismo numero.
func (sc ScoreContexto) NivelConfianza() string {
	switch {
	case sc.ConfianzaPct >= 80:
		return "alta"
	case sc.ConfianzaPct >= 55:
		return "media"
	default:
		return "baja"
	}
}

// evidenciaEsperadaDe traduce la config del kiosko a lo que se le exigia a
// ESTA entrada. Un invitado y un walk-in tienen requisitos distintos, y sin
// esta distincion el score penalizaria al invitado por no traer una INE que su
// kiosko nunca le pidio.
func evidenciaEsperadaDe(cfg *kiosko.KioskoConfig, v Visita) EvidenciaEsperada {
	if cfg == nil {
		return EvidenciaEsperada{}
	}
	// Un RESIDENTE entra por PIN o match facial contra su enrolamiento, nunca
	// por el flujo de visitante -- sin este caso, caía en la rama de abajo y
	// heredaba FotoRostroVisitante/FotoIneVisitante del kiosko, penalizando
	// al residente por no traer una INE que su acceso nunca captura ni pide.
	if v.TipoVisitante == TipoResidente {
		return EvidenciaEsperada{}
	}
	if v.TipoVisitante == TipoConInvitacion {
		return EvidenciaEsperada{
			Rostro:    cfg.FotoRostroInvitado,
			Documento: cfg.IneObligatorioInvitado,
			Placa:     cfg.FotoPlacaInvitado,
		}
	}
	return EvidenciaEsperada{
		Rostro:    cfg.FotoRostroVisitante,
		Documento: cfg.FotoIneVisitante,
		Placa:     cfg.FotoPlacaVisitante,
	}
}
