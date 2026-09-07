# 0031 - Persona + Membresia reemplazan a Residente: identidad global ancla en teléfono

## Status
Accepted

(Reemplaza el modelo `Residente` descrito en [0008](0008-auth-residente-por-pin.md) y
[0020](0020-auto-registro-residente-por-codigo-instalacion.md); ver spec
`2026-08-16-persona-identidad-kigo-design.md`)

## Context
`Residente` (ADR-0008, ADR-0020) modelaba a una persona **dentro** de un tenant: cada fila vivía en
un `CentroHabitacional`, con su PIN y su rostro capturados una sola vez para ese centro. El diseño
funcionaba mientras una persona solo tuviera relación con una instalación, pero se rompía en dos
casos que empezaron a aparecer en la operación real:

- Alguien vive en un condominio administrado con AUTOnomIA y también visita — o se muda a — otro.
  Con `Residente` por tenant, esa persona necesitaba registrarse (y volver a capturar su rostro) una
  vez por cada centro, sin ningún vínculo entre esos registros.
- El enrolamiento facial y el futuro cruce con el marketplace de Kigo Parkimovil (ver
  `docs/integracion-kigo-marketplace-y-face-enrollment.md`) necesitan una identidad que exista **por
  encima** del aislamiento multi-tenant de ADR-0021 — ese aislamiento sigue siendo correcto para los
  datos operativos de un centro (visitas, destinos), pero no para "quién es esta persona".

## Decision
Se introduce `Persona` como identidad Kigo global, deliberadamente fuera de cualquier `tenant_id`, y
`Membresia` como la relación (n:m) entre una `Persona` y un `CentroHabitacional`.

- **`Persona`** (`internal/domain/persona/model.go`) vive en su propia tabla, ancla en `Telefono`
  (`uniqueIndex`, no nulo) — no en el email ni en un id por tenant. Guarda nombre, `Embedding`
  facial, `FotoCaraUrl`, `Curp` y `FotoIneUrl` **una sola vez**, sin importar a cuántos centros
  pertenezca. `KigoUserID` (nullable, `uniqueIndex`) es el único puente hacia una cuenta de Kigo
  Parkimovil — deliberadamente pobre en datos: la mini-app del marketplace nunca recibe teléfono ni
  nombre, solo puede preguntar si un `kigo_user_id` ya está vinculado.
- **Alta por OTP, no por contraseña.** `POST /personas/registro/solicitar-otp` y
  `.../verificar-otp` (`otp_generador.go`, `otp_sender.go`) verifican el teléfono antes de emitir
  cualquier JWT. Mientras no exista un proveedor de SMS real, el código puede mandarse por correo si
  la Persona lo da — el teléfono sigue siendo el ancla, el correo es solo un canal de entrega
  alternativo para el mismo código.
- **`Membresia`** es donde vive todo lo que sí es específico de un centro: `TenantID`, `CasaDestino`,
  `PIN` (hasheado, para el login rápido desde el kiosko — ver ADR-0008), `Rol` (`residente` |
  `invitado_frecuente`) y `Status` (`pendiente` | `activo` | `rechazado`). Unirse a un nuevo centro
  (`POST /personas/me/membresias`) crea una `Membresia` nueva sin tocar la `Persona` ni pedir de
  nuevo INE o rostro.
- **El login del kiosko no cambia de forma.** `POST /kioskos/:id/residentes/{login,verificar-rostro}`
  sigue existiendo con la misma forma (ADR-0008), pero ahora resuelve contra `Persona` + `Membresia`
  (`kiosko_login_handler.go`) en vez de contra `Residente`. El PIN y el rostro siguen siendo
  específicos de la membresía, no de la persona: dos membresías de la misma `Persona` pueden tener
  PINes distintos.
- **El rostro solo se captura una vez, no una vez por membresía.** El wizard de identidad de
  kigo-app llena `Persona.Embedding` al completar el perfil (`POST /personas/me/identidad`); unirse a
  un centro nuevo reutiliza ese embedding para el reconocimiento facial en el kiosko de ese centro.

## Consequences
- Una persona con membresías activas en dos centros se registra, verifica su INE y captura su rostro
  **una sola vez** en la vida de la app, no una vez por centro.
- El aislamiento por tenant de ADR-0021 sigue aplicando a todo lo que consulta `Membresia`
  (visitas, destinos, PIN), pero cualquier consulta por `Telefono`, `Curp` o `Embedding` es
  necesariamente global — hay que revisar caso por caso que ninguna filtre por error datos de otro
  centro solo porque comparten `Persona`.
- El `Embedding` y las fotos de una `Persona` quedan expuestos al reconocimiento facial de **todos**
  los centros donde tenga una membresía activa, no solo al que los capturó originalmente. Es el
  trade-off aceptado a cambio de no volver a pedir la captura.
- `Residente.KioskoID` y las rutas de ADR-0020 quedan sin uso — el código que las resolvía ahora
  vive contra `Persona`+`Membresia`, documentado en el Status de ese ADR.
- Migrar require: cada `Residente` existente se convierte en una `Persona` (usando su teléfono como
  ancla) más una `Membresia` en su tenant original. Personas con el mismo teléfono en dos
  `Residente` de tenants distintos se fusionan en una sola `Persona` con dos membresías.
