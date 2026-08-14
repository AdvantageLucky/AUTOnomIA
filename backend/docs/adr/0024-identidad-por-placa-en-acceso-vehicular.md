# ADR-0024: La placa identifica la visita en un acceso vehicular

**Estado:** Aceptado
**Fecha:** 2026-08-13
**Supercede parcialmente:** ADR-0016 (la INE deja de ser obligatoria para *todo* visitante sin invitación)

## Contexto

ADR-0016 fijó que un visitante sin invitación (`TipoVisitante = VISITANTE`)
siempre debe presentar INE, sin consultar la configuración, porque la CURP es lo
único que liga una visita con las anteriores y sostiene el historial, el análisis
de anomalías y el autopass.

Esa regla se escribió pensando en una caseta peatonal. En un acceso vehicular el
conductor no baja del coche: pedirle que saque la credencial, la acerque a la
cámara y espere el OCR detiene la fila de autos detrás. La operación real de una
caseta vehicular es placa, rostro y destino.

Quitar la INE sin más rompía dos cosas a la vez:

1. **`HistorialPorCURP("")` traduce a `WHERE curp = ''`.** Toda visita sin INE
   caería en el mismo cubo: `VecesVisitado` inflado con visitas de desconocidos,
   `RechazadoPrevio` contagiado desde el rechazo de cualquier otro, y
   `esConfiable` capaz de auto-aprobar a alguien que nunca estuvo ahí si el
   autopass estaba encendido.

2. **`validarOCR("")` devuelve `true`.** La ausencia de CURP se marcaba como OCR
   sospechoso, lo que dejaba `Confiable` en false para siempre y volvía el
   autopass inalcanzable en esos kioskos.

## Decisión

**En un kiosko `VEHICULAR`, para `TipoVisitante = VISITANTE`, la placa ocupa el
lugar de la INE como identificador de la visita.**

1. **Validación por tipo de acceso.** `ValidarCamposCondicionales` recibe ahora
   el `TipoKiosko`. Para vehicular sin invitación: `reqIne = false` y
   `reqPlaca = true` — obligatoria, sin depender del toggle
   `FotoPlacaVisitante`, porque no es una captura opcional sino el identificador.
   El rostro sigue dependiendo de `FotoRostroVisitante`. En peatonal no cambia
   nada: la INE sigue siendo obligatoria.

2. **El historial se agrupa por CURP y, si no hay, por placa.**
   `HistorialDeVisitante` elige el identificador y **nunca consulta con uno
   vacío**: sin CURP ni placa devuelve historial vacío, que es lo correcto —una
   visita sin identificador no tiene pasado que consultar.

3. **`validarOCR` solo marca una CURP capturada y mal formada.** No capturarla
   deja de ser anomalía.

4. **`AnomaliaMatricula` no se evalúa cuando la identidad es la placa.** El
   historial vino agrupado por placa, así que todas las matrículas son iguales
   por construcción y la comparación no diría nada.

5. **`TipoDocumento` gana el valor `PLACA`**, y `Titular` y `TipoDocumento`
   pierden el `binding:"required"` — su obligatoriedad se decide en la
   validación condicional, como ya mandaba ADR-0016 §4. Sin nombre, el handler
   usa la placa como `Titular` para que la visita siga siendo buscable en la
   bitácora (la búsqueda fuzzy de ADR-0012 ya indexa placa).

   Requiere la migración 000033: el `CHECK` de `tipo_documento` en la tabla
   `visitas` enumera los valores permitidos, así que agregar la constante en Go
   sin extender la restricción hace fallar el INSERT con SQLSTATE 23514. La
   misma migración crea `idx_visitas_placa`, porque el historial por placa pasa
   a ejecutarse en cada registro de un kiosko vehicular.

Se descartó un toggle `ine_obligatorio_visitante` configurable por kiosko: habría
que decidir un default, migrar la tabla y explicar en el dashboard una
combinación —vehicular con INE obligatoria— que nadie pidió. El tipo de acceso ya
dice todo lo que hace falta saber.

## Consecuencias

- La caseta vehicular opera a la velocidad de un coche: placa, rostro, destino.
- El visitante vehicular recurrente **sí** acumula historial y puede ganarse el
  autopass, agrupado por su matrícula.
- **La identidad es más débil.** Una placa se clona, se tapa o se cambia; una
  CURP leída de una INE no. Un acceso vehicular acepta menos certeza sobre quién
  entra a cambio de fluidez. Si un centro habitacional no quiere ese trade-off,
  la respuesta es un kiosko peatonal, o un vigilante con el dashboard.
- Dos visitas de la misma persona en coches distintos son, para el sistema, dos
  visitantes distintos. Y dos personas que comparten coche son la misma. Es el
  límite de identificar por vehículo y no por individuo.
- El toggle `foto_placa_visitante` deja de tener efecto en kioskos vehiculares.
  El dashboard lo muestra fijo en encendido y deshabilitado para no prometer algo
  que el flujo ignora.
