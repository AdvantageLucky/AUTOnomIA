package asistente

import (
	"fmt"
	"strings"

	"kigo-autonomia-backend/internal/domain/kiosko"
)

const systemPromptPreguntar = "Eres un asistente amigable en un kiosko de autorregistro de visitantes. " +
	"Respondes preguntas breves (máximo 2 oraciones) en español sobre cómo funciona el registro. " +
	"No inventes información que no tengas: si no sabes algo, dilo claramente y sugiere tocar 'Visitante' o 'Residente' para continuar."

func construirPromptPreguntar(pregunta string, cfg *kiosko.KioskoConfig) string {
	contexto := "Un registro de visitante necesita: identificación oficial (INE) y una foto del rostro."
	if cfg != nil && cfg.MensajeBienvenida != "" {
		contexto += fmt.Sprintf(" Este centro se presenta así: %q.", cfg.MensajeBienvenida)
	}
	if cfg != nil && cfg.HorarioInicio != "" && cfg.HorarioFin != "" {
		contexto += fmt.Sprintf(" El horario de recepción de visitas es de %s a %s.", cfg.HorarioInicio, cfg.HorarioFin)
	}

	return fmt.Sprintf(`### Instrucción
%s

### Contexto
%s

### Pregunta del visitante
%s

### Respuesta
`, systemPromptPreguntar, contexto, pregunta)
}

const systemPromptExtraerCampo = "Eres un extractor de datos silencioso. NUNCA conversas ni respondes preguntas — " +
	"solo devuelves un JSON exacto con el campo pedido, sin texto adicional."

func construirPromptPlaca(transcripcion string) string {
	return fmt.Sprintf(`### Instrucción
%s
Extrae una placa vehicular mexicana de la transcripción. Normaliza letras/dígitos hablados a su forma escrita
(ej. "a b c uno dos tres" -> "ABC123"). Responde EXACTAMENTE en este formato JSON, nada más:
{"valor": "<placa o null si no se entiende>", "confianza": <0.0 a 1.0>}

### Transcripción
%s

### JSON
`, systemPromptExtraerCampo, transcripcion)
}

// construirPromptMotivo extrae el motivo de visita de una transcripción que
// puede ser larga o enredada ("vengo a dejarle un paquete a mi tía porque
// hoy es su cumpleaños y quiero darle la sorpresa...") -- a diferencia de
// destino, no hay catálogo contra el cual matchear: el motivo es y siempre
// ha sido texto libre, así que aquí el LLM solo limpia/resume la
// transcripción a una frase breve y clara, sin inventar información que la
// persona no dijo. Solo responde null si la transcripción no tiene ningún
// motivo reconocible (silencio, ruido, "no sé", etc.).
func construirPromptMotivo(transcripcion string) string {
	return fmt.Sprintf(`### Instrucción
%s
Resume el motivo de la visita en una frase breve y clara (máximo 15 palabras), en español, sin inventar
información que la persona no haya dicho. Si la transcripción no describe ningún motivo reconocible
(silencio, ruido, "no sé", etc.), responde valor null. Responde EXACTAMENTE en este formato JSON, nada más:
{"valor": "<motivo resumido o null>", "confianza": <0.0 a 1.0>}

### Transcripción
%s

### JSON
`, systemPromptExtraerCampo, transcripcion)
}

func construirPromptDestino(transcripcion string, destinosValidos []string) string {
	lista := strings.Join(destinosValidos, ", ")
	return fmt.Sprintf(`### Instrucción
%s
Identifica a cuál de estos destinos EXACTOS se refiere la transcripción — nunca inventes uno que no esté en la lista.
Si no coincide claramente con ninguno, responde valor null. Responde EXACTAMENTE en este formato JSON, nada más:
{"valor": "<uno de los destinos exactos, o null>", "confianza": <0.0 a 1.0>}

### Destinos válidos
%s

### Transcripción
%s

### JSON
`, systemPromptExtraerCampo, lista, transcripcion)
}
