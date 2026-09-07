# ADR-0005: Deep links con esquema propio `kigoapp://` para invitaciones

**Estado:** Aceptado
**Fecha:** 2026-08-31

## Contexto

Una invitación creada en kigo-app necesita poder compartirse por fuera de la app (WhatsApp, SMS) y,
si quien la recibe ya tiene la app instalada, abrirla directo ahí en vez de en un navegador. Firebase
Dynamic Links —la solución típica para deep linking diferido (funciona incluso si la app todavía no
está instalada)— fue dado de baja por Google, así que esa opción no estaba disponible.

## Decisión

1. **Esquema propio `kigoapp://invitacion/<token>`**, escuchado por `DeepLinkServicio` vía el
   paquete `app_links`. El token no "reclama" nada: la invitación ya llegó asociada a la `Persona`
   destinataria por teléfono desde el momento en que se creó (`CrearInvitacion` en el backend) — el
   deep link solo sirve para llevar a la persona directo a verla, no para vincularla.

2. **Sin la app instalada, el link cae en una landing web (`/i/:token`)** desde donde se puede
   descargar la app. Si esa misma persona abre el link de nuevo ya con la app instalada, el listener
   de `app_links` sí lo recibe — cubre el caso común sin necesitar deep linking diferido de verdad,
   al costo de que el primer intento (antes de instalar) nunca resuelve directo a la invitación.

3. **El token pendiente se persiste una sola vez y se consume al entrar al shell principal**
   (`DeepLinkServicio.tomarTokenPendiente`, respaldado en `shared_preferences`) — cubre el caso en
   que el sistema operativo entrega la URI antes de que la app termine de arrancar
   (`getInitialLink()`), sin depender de que `KigoShell` ya esté montado en ese instante.

## Consecuencias

Positivas:
- No depende de ningún servicio de terceros para deep linking (evita la ruta que Google discontinuó).
- El esquema es simple de razonar: el link nunca autoriza nada por sí mismo, solo navega — no hay
  superficie de seguridad nueva que proteger en el cliente.

Negativas / Trade-offs:
- **No hay deep linking diferido real.** Alguien sin la app instalada que toca el link, instala la
  app y la abre por primera vez desde el ícono (no volviendo a tocar el link) nunca ve la invitación
  automáticamente — tiene que encontrarla por su cuenta en "Solicitudes"/"Recibidas".
- Un esquema propio (`kigoapp://`) no es *verificable* por el sistema operativo de la misma forma
  que un dominio con App Links/Universal Links firmado — cualquier otra app podría en teoría
  registrar el mismo esquema.
