# ADR-0014: WebSockets para solicitudes en tiempo real (pendiente)

**Estado:** Pendiente  
**Fecha:** 2026-07-17

## Contexto

El polling de 15s implementado en ADR-0013 tiene una latencia máxima de 15 segundos. En un condominio con tráfico alto esto puede ser problemático — el vigilante ve la solicitud con retraso.

La alternativa real es WebSockets: el backend empuja cada nueva `Visita PENDIENTE` al dashboard en tiempo real.

## Decisión

**Pendiente.** Se implementará cuando el polling demuestre ser insuficiente en producción.

### Propuesta técnica cuando se implemente

- **Librería**: `github.com/gorilla/websocket` (estándar de facto en Go).
- **Endpoint**: `GET /api/v1/ws/solicitudes` — el dashboard establece la conexión al cargar la tab Solicitudes. Requiere JWT en query param (`?token=...`) porque los WebSocket headers no soportan `Authorization`.
- **Eventos**: el backend emite un evento JSON `{"tipo": "nueva_solicitud", "visita": {...}}` cada vez que se crea una `Visita` con estado `PENDIENTE`.
- **Arquitectura**: un hub centralizado con canales Go maneja las conexiones activas y hace fan-out de eventos por `AdminID`.
- **Reconexión**: el cliente reintenta con backoff exponencial (1s, 2s, 4s, 8s, max 30s).

## Consecuencias

- Requiere cambios en el servidor HTTP (Gin soporta upgrade a WebSocket).
- El dashboard necesita manejar reconexión automática.
- La app de residente también se beneficiaría de este canal para recibir solicitudes entrantes sin polling.
