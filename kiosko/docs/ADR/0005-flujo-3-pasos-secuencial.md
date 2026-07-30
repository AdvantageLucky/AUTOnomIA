# ADR-0005: Flujo de registro en 3 pasos secuenciales con StepIndicator

**Estado:** Superseded by 0013
**Fecha:** 2026-06-01
**Autores:** Ivan Ramirez

## Contexto

El proceso de registro de un visitante en el kiosco requiere tres
acciones del usuario: escaneo de INE, captura de rostro y confirmación
de datos. Se necesitaba definir si estas pantallas serían tabs navegables
libremente, un stepper lineal o vistas apiladas con Navigator.

## Decisión

Implementamos un flujo estrictamente secuencial usando Navigator.push
entre pasos. El usuario no puede avanzar sin completar el paso actual
ni retroceder al paso anterior desde la pantalla de confirmación.
Un StepIndicator visual en la parte superior muestra el progreso:
Paso 1 = INE, Paso 2 = Rostro, Paso 3 = Confirmación.

El ViewModel expone indicatorStep (paso actual para el indicador) y la
constante indicatorTotalSteps = 3, desacoplando el indicador visual
del conteo interno de pasos que incluye una pantalla introductoria.

## Consecuencias

Positivas:
- El flujo es imposible de romper: no se puede llegar a confirmación
  sin tener datos de INE y foto de rostro válidos.
- El StepIndicator desacoplado permite cambiar el conteo interno de
  pasos sin afectar la UI visual.

Negativas / Trade-offs:
- El usuario no puede corregir su INE si ya avanzó al paso de rostro
  sin retroceder manualmente.
- La pantalla introductoria (paso 0 interno) no tiene representación
  en el StepIndicator, lo que requiere el offset de -1 en indicatorStep.