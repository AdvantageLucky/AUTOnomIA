# 0008 - Autenticación del residente por PIN numérico

## Status
Accepted

## Context
La app residente permite a los residentes del condominio aprobar o rechazar solicitudes de kiosko
pendientes (`Visita.estado = PENDIENTE`). Necesita un mecanismo de autenticación distinto al del
admin y al del kiosko.

Para el admin se usa email + contraseña con JWT de 24h — razonable para un operador humano con
un dispositivo conocido. Para el kiosko se usa una clave opaca persistida porque es un dispositivo
desatendido que nunca debe re-autenticarse (ver [0004](0004-auth-dual-mecanismo.md)).

El residente es un usuario final no técnico que usa la app desde su teléfono personal. Un PIN
numérico de 4-8 dígitos (como los PINs bancarios) tiene la menor fricción de login posible sin
exponer un password complejo que el usuario anotará en papel. La app residente es de uso interno
en el condominio; el vector de ataque relevante es un extraño en el mismo complejo que consigue el
teléfono desbloqueado, no un atacante remoto.

## Decision
El modelo `Residente` almacena el PIN hasheado con bcrypt (costo 12). El login es
`POST /auth/residente/login` con `{ casa_destino, pin, kiosko_id }` — el `casa_destino` actúa
como identificador de usuario (es único por `kiosko_id`) y el `pin` como contraseña.

El login exitoso devuelve un JWT firmado con HS256, TTL de 7 días, con claim `residente_id`.
El middleware `RequireResidente` valida ese token y expone el `residente_id` en el contexto de
gin via la clave `ctxkeys.ResidenteID`. El JWT de residente tiene una firma distinta al del admin;
ambos usan `JWT_SECRET` del entorno pero claims distintas — un token de residente no puede usarse
en rutas `RequireAdmin` porque los claims no coinciden.

La creación de residentes (`POST /residentes/`) está protegida con `RequireAdmin`; el residente
no puede auto-registrarse.

## Consequences
- El PIN debe tener un mínimo de longitud que el handler valida antes de hashear; si el admin
  crea un residente con PIN "1234" el sistema lo acepta — la política de complejidad queda en
  el criterio del administrador por ahora.
- 7 días de TTL significa que un teléfono robado da kiosko a la app hasta que el admin elimine
  al residente o lo recree con nuevo PIN. Si se necesita revocación inmediata habría que migrar
  a sesiones persistidas como el kiosko.
- `casa_destino` como username ata la identidad del residente a su ubicación física. Si el
  residente cambia de unidad, el Admin debe eliminar el registro y crear uno nuevo con la
  nueva `casa_destino`.
- La app residente actual tiene credenciales hardcodeadas (`ivan@kigo.com`) que **no coinciden**
  con este mecanismo — la integración de la app con este endpoint es trabajo pendiente.
