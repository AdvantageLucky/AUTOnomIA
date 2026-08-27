# 0020 - Auto-registro de residentes por código de instalación

## Status
Superseded — el modelo `Residente` y sus rutas (incluidas las de este ADR) fueron eliminados por
completo; kigo-app migró su identidad a `Persona` (teléfono + OTP) y la afiliación a un centro pasó
a modelarse como `Membresia`. El login/registro por PIN o rostro desde el kiosko sigue existiendo
bajo las mismas rutas `POST /kioskos/:id/residentes/{login,verificar-rostro}`, pero ahora resuelve
contra `Persona`+`Membresia` (ver `internal/domain/persona/kiosko_login_handler.go`).

(Reemplazaba a [0008](0008-auth-residente-por-pin.md))

## Context
[0008](0008-auth-residente-por-pin.md) definió dos reglas que la operación real invalidó:

1. El login es `POST /auth/residente/login` con `{ casa_destino, pin, kiosko_id }`.
2. «La creación de residentes está protegida con `RequireAdmin`; el residente no puede
   auto-registrarse.»

Los problemas concretos:

- El `kiosko_id` es un identificador interno de base de datos. El residente no tiene forma de
  conocerlo ni de recordarlo, y obligaba al admin a comunicárselo por fuera del sistema. La pantalla
  de login de la app pedía literalmente «ID del kiosko», que para un usuario final no significa nada.
- Con multi-tenant ([0018](0018-multitenancy-centro-habitacional.md)) el `casa_destino` es único
  **por tenant**, no por kiosko. El `kiosko_id` dejó de ser el discriminante correcto para resolver
  a qué residente corresponde una casa.
- El alta manual no escala. Un fraccionamiento de 200 casas obliga al admin a crear 200 residentes
  a mano, cada uno con su PIN, y a comunicar ese PIN a cada persona.

## Decision
Sustituir el `kiosko_id` por el **código público de la instalación** como identificador que el
residente sí puede conocer, y permitir el auto-registro con aprobación posterior del admin.

- `CentroHabitacional` gana un campo `codigo`, público y con índice único (ej. `FEPRO-2026`). Es
  obligatorio en el asistente de configuración inicial del dashboard.
- Endpoints públicos, todos derivando el tenant a partir del código:
  - `GET  /centros/buscar?codigo=...` — valida el código y devuelve el nombre de la instalación.
  - `GET  /centros/:codigo/destinos` — nombres de los destinos del tenant.
  - `POST /centros/:codigo/residentes/auto-registro` — alta en estado `pendiente`.
  - `GET  /centros/:codigo/residentes/estado` — consulta del estado de la solicitud.
  - `POST /centros/:codigo/residentes/login` — login sin `kiosko_id`.
- El residente se auto-registra con nombre, teléfono, casa —elegida de la lista de destinos del
  tenant, no escrita a mano—, PIN y foto de rostro. Queda en `status = pendiente`.
- El admin aprueba o rechaza desde el dashboard (Residentes → Solicitudes). Solo un residente con
  `status = activo` puede iniciar sesión.
- El JWT de residente y el middleware `RequireResidente` de [0008](0008-auth-residente-por-pin.md)
  **no cambian**. Lo que cambia es cómo se llega a emitirlo.
- `Residente.KioskoID` pasa a ser nullable: un auto-registro no está atado a ningún kiosko.

## Consequences
- El trabajo del admin pasa de dar de alta a cada residente a aprobar solicitudes, que es una
  decisión de una sola pulsación.
- El código de instalación es una credencial de **descubrimiento**, no de acceso. Conocerlo permite
  ver los destinos y enviar una solicitud; no otorga entrada, porque la aprobación del admin es
  obligatoria.
- `GET /centros/:codigo/destinos` expone públicamente los nombres de las casas del tenant a quien
  tenga el código. Es un trade-off deliberado: sin esa lista el residente escribiría su casa a mano
  y cualquier variante tipográfica rompería el match contra `casa_destino`, que es lo que ata al
  residente con las visitas dirigidas a él.
- `FindPorPinPublico` recorre los residentes de la casa comparando el hash bcrypt uno por uno. Es
  O(n) sobre los residentes de esa casa, no sobre todo el tenant, así que se mantiene acotado; si
  una casa llegara a tener muchos habitantes convendría un identificador explícito por persona.
- Si dos residentes de la misma casa eligen el mismo PIN, el login resuelve al primero que haga
  match. Falta forzar unicidad de PIN dentro de una misma casa.
- El auto-registro depende de que existan destinos cargados. Por eso el asistente de configuración
  inicial del dashboard incluye un paso dedicado a darlos de alta.
- El auto-registro sube una foto de rostro por `multipart/form-data`; el backend solo acepta
  `image/jpeg` e `image/png`, así que el cliente debe declarar el `Content-Type` explícitamente.
