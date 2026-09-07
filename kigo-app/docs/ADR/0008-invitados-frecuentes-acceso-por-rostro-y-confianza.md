# ADR-0008: Invitados frecuentes con acceso por rostro, y control de "confianza" por identidad

**Estado:** Aceptado
**Fecha:** 2026-09-01 (extendido 2026-09-04 con Identidades y confianza)
**Relacionado:** ADR-0003 (Persona + Membresia), kiosko ADR-0016 (huella facial on-device)

## Contexto

Un residente recibe visitas recurrentes (pareja, empleada doméstica, familiar cercano) para las que
generar una invitación QR cada vez es fricción innecesaria. El backend ya modela esto como un rol de
`Membresia` (`invitado_frecuente`, distinto de `residente`) más que como un mecanismo aparte: la
persona entra por reconocimiento facial en el kiosko exactamente igual que un residente — el rol solo
cambia sus permisos, no el mecanismo de acceso. Faltaba, del lado de kigo-app, dar de alta ese rol y,
por otro lado, darle a un residente control sobre el rastro biométrico/de contacto que va dejando cada
identidad que ha visitado su casa.

## Decisión

1. **Dar de alta un invitado frecuente es distinguible de invitar por QR**, pero termina en el mismo
   backend: la pestaña de acceso frecuente en "Invitar" enrola a la persona con `Rol =
   invitado_frecuente` en vez de generar una invitación de un solo uso. `InvitadoFrecuenteModel`
   expone tanto el `id` de la `Membresia` (para revocar el acceso) como el `personaId` (la identidad
   subyacente, necesaria para pedir un reset de confianza sobre ella — ver punto 3).

2. **Eliminar la invitación que originó un enrolamiento revoca también el acceso** — un invitado
   frecuente no queda con acceso huérfano si la invitación por la que llegó se borra después.

3. **`IdentidadesConfianzaViewModel`** (pantalla "Identidades y confianza") lista, acotado a "solo lo
   mío", cualquier identidad que haya visitado la casa del residente autenticado — residentes,
   invitados por QR, visitantes con INE — vía `GET
   /personas/me/identidades-mi-casa?tenant_id=...`, y permite "resetear" el historial acumulado con
   una de ellas (`POST .../resetear-historial`). Es la misma capacidad que ya tenía el admin desde el
   dashboard, pero acotada a la propia casa del residente, no a todo el tenant.

4. **El reset se resuelve por la clave que esa identidad sí tenga**, en orden de preferencia:
   `personaId` (identidad con cuenta) → `curp` (visitante identificado por INE sin cuenta) →
   `visitaRepresentativaId` (solo un registro de rostro, sin ninguna otra identificación) — nunca
   asume que las tres claves están disponibles a la vez.

## Consecuencias

Positivas:
- Un invitado frecuente entra por rostro con la misma experiencia que un residente, sin que el
  kiosko necesite ninguna lógica nueva de reconocimiento — el rol vive enteramente en el backend.
- Un residente puede "olvidar" el historial de contacto con alguien (ex-pareja, empleada que ya no
  trabaja ahí) sin depender de que el administrador lo haga por él.

Negativas / Trade-offs:
- Un invitado frecuente puede entrar por rostro a cualquier hora sin que medie una invitación
  puntual — la mitigación de abuso depende enteramente de que el residente recuerde revocarlo
  (eliminar la membresía o la invitación que lo originó).
- El "reset de confianza" borra el rastro de contacto, pero no revoca por sí mismo un acceso ya
  vigente (un `invitado_frecuente` sigue entrando por rostro tras un reset, salvo que además se
  revoque su membresía) — son dos acciones distintas que pueden confundirse desde la UI.
- Resolver el reset contra tres claves distintas (personaId/curp/rostro) según qué tan identificada
  esté la visita hace que la vista deba manejar tres formas de URL distintas para la misma acción
  conceptual.
