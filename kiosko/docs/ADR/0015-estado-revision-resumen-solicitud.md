# ADR-0015: Estado REVISION distinto en el resumen de solicitud, con regreso automático

**Estado:** Aceptado
**Fecha:** 2026-08-04
**Autores:** Alberto Luna y Jesus Mendoza

## Contexto

El PRD de self check-in exige que, si el anfitrión no responde en el
tiempo definido, la solicitud caiga a revisión manual sin quedar
colgada ni perderse, con un mensaje distinto y visible para el
visitante por cada estado posible.

Antes de este cambio, `ResumenSolicitudView` trataba `REVISION` igual
que `PENDIENTE` (ambos agrupados bajo el getter `_esperandoAprobacion`):
mostraba indefinidamente "Esperando aprobación…" y nunca detenía el
polling ni el spinner. El visitante no tenía forma de saber que su
solicitud había escalado a revisión, y el kiosko no regresaba solo a
la pantalla de bienvenida en ese caso — a diferencia de aprobado y
rechazado, que sí lo hacían después de 1 minuto (ver ADR-0013).

Esta vista es solo el lado kiosko/visitante. La lógica que efectivamente
mueve la solicitud a `REVISION` tras el tiempo de espera vive en el
backend — ver ADR-0016 del backend para esa parte.

## Decisión

`_esperandoAprobacion` ahora cubre únicamente `PENDIENTE`. `REVISION`
se trata como una tercera rama visual, no como una variante de "sigue
esperando":

- Ícono de reloj de arena, texto "En revisión manual" y subtítulo "Un
  vigilante revisará tu acceso en breve", en el mismo color ámbar que
  usa el badge de `REVISION` en el dashboard admin (ver ADR-0016 del
  backend).
- Al detectar `REVISION` por primera vez — comparando el estado previo
  contra el nuevo antes de aplicar el `setState`, para no disparar dos
  veces si un ciclo de polling se solapa con el anterior — se muestra
  un `AlertDialog` no descartable: "La solicitud pasó el tiempo límite
  de respuesta, tu solicitud pasó a revisión manual. Un vigilante te
  atenderá en breve."
- Se reutiliza el mismo patrón que ya existía para aprobado/rechazado:
  se detiene el polling y arranca el `Timer` de 1 minuto que regresa a
  bienvenida (`popUntil` a la raíz). Decisión explícita de que el
  comportamiento fuera idéntico al de los otros dos estados terminales,
  no solo visualmente parecido.

## Consecuencias

Positivas:
- El visitante ya no se queda viendo un spinner indefinido si su
  solicitud escala a revisión.
- El kiosko queda libre para el siguiente visitante sin intervención
  humana, igual que en los otros dos estados terminales.
- Cierra el criterio del PRD de "mensaje de resultado claro y distinto
  por cada estado" para los tres casos (aprobado / rechazado /
  revisión), antes solo cubría dos.

Negativas / Trade-offs:
- Si el vigilante aprueba o rechaza la solicitud durante ese minuto de
  espera, el kiosko no lo refleja — el visitante ya vio el mensaje de
  revisión y el kiosko regresa a bienvenida sin mostrar el resultado
  final real. Es el mismo trade-off que ya aceptaba ADR-0013 para
  aprobado/rechazado, ahora también aplica a revisión.
- El texto del diálogo está hardcodeado en español, sin pasar por
  ningún sistema de i18n (el kiosko no tiene uno; el dashboard admin sí,
  ver ADR-0010 del backend).
