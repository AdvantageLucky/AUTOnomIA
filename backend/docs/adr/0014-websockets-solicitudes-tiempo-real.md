# ADR-0014: Tiempo real para solicitudes — SSE en vez de WebSockets

**Estado:** Aceptada (reemplaza la propuesta original de este mismo ADR)
**Fecha:** 2026-07-17 · **Actualizada:** 2026-09-03

## Contexto

El polling de 15s implementado en ADR-0013 tenía una latencia máxima de 15 segundos. En un condominio con tráfico alto esto podía ser problemático — el vigilante veía la solicitud con retraso.

Este ADR originalmente proponía WebSockets como solución (ver la propuesta técnica al final, conservada como referencia). Al implementarse, se optó por **Server-Sent Events (SSE)** en su lugar.

## Decisión

**SSE, no WebSockets.** `GET /api/v1/kioskos/solicitudes/stream` (`internal/domain/visitas/handlers.go:StreamSolicitudes`) mantiene una conexión HTTP abierta (`Content-Type: text/event-stream`) y empuja cada evento con el formato `data: <json>\n\n` a través de un hub de canales Go (`sseHub`, pub/sub) — el mismo patrón que ya usa `GET /kioskos/:id/config/stream` para empujar cambios de configuración al kiosko.

**Por qué SSE y no WebSockets:** el flujo dashboard↔servidor es unidireccional (servidor → cliente); el dashboard nunca necesita mandar nada por ese canal, solo recibir. SSE es HTTP plano — pasa por cualquier proxy sin configuración especial, reconecta solo (comportamiento nativo de `EventSource`, sin necesitar el backoff manual que sí exigía la propuesta de WebSockets), y no necesita un protocolo ni una librería aparte (`gorilla/websocket`). WebSockets se habría justificado con tráfico bidireccional, que este canal no tiene.

## Consecuencias

- Un solo mecanismo (hub de canales Go + SSE) sirve tanto el feed de solicitudes del dashboard como la config en caliente del kiosko — no hay dos sistemas de tiempo real distintos que mantener.
- El cliente no necesita lógica de reconexión propia: `EventSource` reintenta solo.
- Sigue siendo unidireccional: si en el futuro el dashboard necesitara enviar algo por ese mismo canal (no solo recibir), esta decisión se revisitaría — hoy no hay ese caso de uso.

---

### Propuesta original (WebSockets, no implementada — conservada como referencia)

- **Librería**: `github.com/gorilla/websocket` (estándar de facto en Go).
- **Endpoint**: `GET /api/v1/ws/solicitudes` — el dashboard establece la conexión al cargar la tab Solicitudes. Requiere JWT en query param (`?token=...`) porque los WebSocket headers no soportan `Authorization`.
- **Eventos**: el backend emite un evento JSON `{"tipo": "nueva_solicitud", "visita": {...}}` cada vez que se crea una `Visita` con estado `PENDIENTE`.
- **Arquitectura**: un hub centralizado con canales Go maneja las conexiones activas y hace fan-out de eventos por `AdminID`.
- **Reconexión**: el cliente reintenta con backoff exponencial (1s, 2s, 4s, 8s, max 30s).

Se descartó porque exigía una librería y un protocolo de transporte aparte solo para ganar la dirección servidor→cliente que SSE ya cubre de forma más simple, sobre HTTP plano.
