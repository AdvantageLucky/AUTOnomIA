# ADR-0013: Aprobación manual de solicitudes desde el dashboard

**Estado:** Aceptado  
**Fecha:** 2026-07-17

## Contexto

Un visitante que se registra en el kiosko genera una `Visita` en estado `PENDIENTE`. Lo esperado es que el residente la apruebe o rechace desde su app. Sin embargo, hay casos donde el residente no responde:

1. No tiene la app instalada o no la usa.
2. No contestó en el tiempo de espera configurado.
3. El visitante no va a ver a ningún residente (vendedor, técnico, visita a administración).

En estos casos el vigilante o administrador del condominio debe poder intervenir directamente desde el dashboard.

## Decisión

### Tab "Solicitudes" en el dashboard

Vista dedicada que muestra `Visitas` con `estado = PENDIENTE`, ordenadas por `created_at` descendente. No es una entidad nueva: es una vista filtrada sobre el modelo existente.

Cada fila muestra: nombre, foto (thumbnail), casa destino, kiosko, tiempo transcurrido, y botones **Aprobar** / **Rechazar**.

Al aprobar o rechazar se llama `PATCH /api/v1/visitas/:id` con `{"estado": "APROBADO"}` o `{"estado": "RECHAZADO"}` y el row desaparece de la lista.

### Polling

El dashboard refresca la lista de solicitudes pendientes cada **15 segundos** mediante `setInterval`. Es suficiente para el volumen esperado y no requiere infraestructura adicional. Ver ADR-0014 para la evolución a WebSockets.

### Permisos

El endpoint `PATCH /api/v1/visitas/:id` ya existe y requiere JWT de admin. El campo `estado` es el único que puede modificar el admin desde este endpoint (el resto de campos de la visita son inmutables post-creación).

## Consecuencias

- Solución funcional sin WebSockets, con latencia máxima de 15s.
- El `PATCH` debe validar que solo modifique `estado` y que el valor sea `APROBADO` o `RECHAZADO`.
- Si en el futuro se añaden WebSockets (ADR-0014), el polling se puede desactivar sin cambios en el backend.
