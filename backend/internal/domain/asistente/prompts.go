package asistente

import (
	"fmt"

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
