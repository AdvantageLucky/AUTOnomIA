# 0004 - Autenticación dual: JWT para Admin, sesión persistida para kiosko

## Status
Accepted

## Context
El sistema tiene dos tipos de cliente muy distintos golpeando la API:

- El **dashboard del Admin**, un cliente web tradicional donde una persona inicia sesión y navega.
- El **kiosko**, una tablet desatendida en una entrada física que queda logeada por tiempo
  indefinido y necesita registrar visitantes sin intervención humana repetida.

Un JWT stateless es razonable para el Admin (login esporádico, expiración corta aceptable, no hay
necesidad de revocación inmediata). Pero para el kiosko, un dispositivo desatendido que se puede
dañar o cambiar, se necesita poder **revocar el kiosko de inmediato** desde el dashboard sin esperar
a que expire un token — algo que un JWT puro no permite sin infraestructura adicional (blacklist,
TTL corto + refresh, etc.).

También se evaluó modelar el kiosko como una entidad `Kiosko` separada de `Kiosko`, pero en la
Propuesta Técnica una "instancia de kiosko" mapea 1 a 1 con lo que ya es `Kiosko` (ej. "Entrada A",
"Puerto 3") — crear una entidad aparte solo para guardar una credencial habría duplicado esa
relación 1 a 1 sin necesidad.

## Decision
`internal/domain/auth/` implementa **dos mecanismos de autenticación distintos**, cada uno
expuesto bajo `/auth`:

- **Admin** (`POST /auth/sign-in`, `POST /auth/login`): JWT firmado con HS256
  (`github.com/golang-jwt/jwt/v5`), válido 24h, sin estado en base de datos. El middleware
  `auth.RequireAdmin` valida el JWT del header `Authorization: Bearer <token>` y mete el
  `admin_id` en el contexto de gin.
- **Kiosko** (`POST /auth/kiosko/login`): la credencial (`ClaveKiosko`, hash bcrypt) vive
  directamente en el modelo `Kiosko`, no en una entidad separada. El login abre una
  `SesionKiosko` persistida en la tabla `sesion_kioskos`, con un token opaco de alta entropía
  (no JWT). El middleware `auth.RequireAcceso` valida ese token contra la tabla y mete el
  `kiosko_id` de la sesión en el contexto. `POST /auth/kiosko/{id}/revocar` (protegido con
  `RequireAdmin`, validando que el Kiosko pertenece al admin autenticado) revoca todas las
  sesiones activas de ese Kiosko de inmediato.

Ambas llaves de contexto (`admin_id`, `kiosko_id`) viven en `internal/platform/ctxkeys/`, un
paquete sin dependencias, para que `kiosko/`, `admin/` y `visitantes/` puedan leerlas en sus
handlers sin crear un ciclo de imports con `auth/` (que a su vez depende de `kiosko/` y `admin/`
para resolver el login).

## Consequences
- Las rutas de dashboard (`/admins`, `/kioskos`, `/visitantes` planas) quedan protegidas con
  `RequireAdmin`; las rutas anidadas de registro de visitantes (`/kioskos/:id/visitantes`) quedan
  protegidas con `RequireAcceso`, verificando además que el `:id` de la URL coincide con el
  `kiosko_id` de la sesión — un kiosko logeado en el Kiosko 3 no puede operar sobre el Kiosko 5
  solo cambiando la URL.
- Revocar un kiosko robado/perdido es inmediato (un `UPDATE` en `sesion_kioskos`), a costa de una
  consulta a base de datos en cada request del kiosko (vs. la verificación de firma in-memory de
  un JWT para el Admin).
- Dos mecanismos de auth en el mismo paquete es más código que uno solo, pero evita forzar al
  kiosko a comportarse como un cliente que puede re-autenticarse fácilmente cuando expira un
  token — no es ese tipo de dispositivo.
