# ADR-0006: Push notifications (FCM) con navegación dirigida y refresco reactivo

**Estado:** Aceptado
**Fecha:** 2026-08-26
**Relacionado:** backend ADR-0029 (FCM real con respaldo a notificador falso)

## Contexto

Antes de esta decisión, tocar una notificación push no hacía nada más que el comportamiento por
default del sistema operativo: abría la app donde sea que se hubiera quedado, sin llevar a la
persona a la solicitud o invitación real que motivó el aviso. Además, el badge de "Solicitudes" en
`KigoShell` solo se actualizaba al tocar esa pestaña — si una solicitud se resolvía por otro medio
(otro residente de la misma casa, el kiosko, o vencimiento automático) mientras la app seguía abierta
en otra pestaña, el badge quedaba desactualizado indefinidamente.

## Decisión

1. **`PushService`** pide permiso, registra y mantiene actualizado el token FCM del dispositivo
   (`POST /personas/me/device-token`) — el registro es *fire-and-forget*: si falla, no debe romper
   ni el login ni el resto de la app (`catch` silencioso a propósito).

2. **El backend manda un campo `tipo` en el payload de datos de cada push** (ver
   `pushSender.Send(...)`); el cliente lo usa para decidir a dónde navegar cuando la persona **toca**
   la notificación, cubriendo los tres estados posibles de la app: en foreground
   (`FirebaseMessaging.onMessage`, solo un `SnackBar` y un refresh, sin navegar porque la persona ya
   está dentro), en background (`onMessageOpenedApp`) y cerrada por completo
   (`getInitialMessage()`, el "primer mensaje" que relanzó la app).

3. **Dos `ValueNotifier` estáticos en `MyApp` desacoplan la señal del momento en que se consume:**
   `notificationTick` (se incrementa con cualquier notificación, dispara un refresh) y
   `pushNavigationTipo` (el tipo de la última notificación *tocada*, para navegar). Son
   `ValueNotifier` en vez de un valor consumido una sola vez porque `PushService.iniciar()` corre en
   paralelo al arranque (llamado fire-and-forget desde `AuthViewModel`) y no hay garantía de que ya
   haya resuelto `getInitialMessage()` para cuando `KigoShell` monta por primera vez — reaccionar a
   cambios cubre ese caso sin depender de un orden de arranque específico.

## Consecuencias

Positivas:
- Tocar una notificación lleva siempre a la pantalla relevante (Invitar/Recibidas,
  Invitar/Mis invitaciones, o Solicitudes), sin importar en qué estado estaba la app.
- El badge de Solicitudes se mantiene correcto aunque la solicitud se resuelva por un canal que no es
  esta misma sesión de la app (otro residente, el kiosko, vencimiento).

Negativas / Trade-offs:
- El registro del device token es silenciosamente best-effort: si falla, la persona sigue sin recibir
  push y no hay ningún indicador en la UI de que eso ocurrió.
- Depender de dos `ValueNotifier` globales acopla `KigoShell` a variables estáticas de `MyApp` en vez
  de un mecanismo de eventos más explícito — funciona mientras solo `KigoShell` necesite escucharlos,
  pero no escala bien a un tercer consumidor sin duplicar la misma lógica de "reaccionar a un cambio,
  no a un valor consumido una vez".
