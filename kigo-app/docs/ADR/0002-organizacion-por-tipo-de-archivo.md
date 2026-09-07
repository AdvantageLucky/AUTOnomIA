# ADR-0002: Organización por tipo de archivo, no por feature

**Estado:** Superseded por [ADR-0009](0009-migracion-a-arquitectura-por-feature.md)
**Fecha:** 2026-07-12
**Relacionado:** kiosko ADR-0002 (arquitectura por feature)

## Contexto

El kiosko migró de organización por tipo de archivo a organización por feature (`lib/features/`)
cuando el número de flujos creció y modificar uno solo obligaba a saltar entre cuatro carpetas
distintas (ADR-0002 de kiosko). kigo-app parte del mismo punto de partida —
`lib/models/`, `lib/services/`, `lib/viewmodels/`, `lib/views/`— pero con una superficie bastante
más chica: media docena de flujos (invitar, solicitudes, historial, ajustes, identidades de
confianza, compañeros de casa) en vez de las decenas de pantallas y variantes del kiosko
(peatonal/vehicular, con/sin invitación, tres wizards distintos de captura).

## Decisión

kigo-app se queda con la organización por tipo de archivo. No se replica la estructura
`lib/features/<nombre>/{models,services,viewmodels,views}` del kiosko.

La única carpeta que rompe ese patrón es `lib/views/onboarding/`, que agrupa el wizard completo de
alta (bienvenida → teléfono → OTP → identidad → unirse a centro → espera) con sus propios
`widgets/` anidados, incluyendo el sub-wizard de identidad (`widgets/identidad/`) — es el único flujo
de kigo-app con suficientes pasos y estado propio como para justificar agruparse aparte del resto.

## Consecuencias

Positivas:
- Con pocos archivos por carpeta, encontrar "todos los modelos" o "todos los ViewModels" es
  inmediato sin necesitar saber antes a qué feature pertenecen.
- No hubo que decidir, para cada archivo nuevo, si algo "verdaderamente transversal" va a
  `core/` o a una feature — decisión que el kiosko sí necesita resolver constantemente.

Negativas / Trade-offs:
- Si kigo-app sigue creciendo al ritmo del kiosko, es previsible que en algún punto valga la pena
  la misma migración a `features/` que ya hizo el kiosko — este ADR documenta la decisión de no
  hacerlo *todavía*, no un rechazo permanente al patrón.
- El wizard de onboarding ya es la excepción a la regla general; si aparece un segundo flujo con esa
  misma complejidad, la organización por tipo de archivo empieza a mezclar dos criterios distintos
  sin una regla clara de cuándo aplica cada uno.
