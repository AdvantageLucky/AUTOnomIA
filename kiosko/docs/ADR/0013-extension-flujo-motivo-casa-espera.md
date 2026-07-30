# ADR-0013: Extensión del registro con motivo, casa destino y espera de aprobación

**Estado:** Aceptado
**Fecha:** 2026-07-29
**Autores:** Alberto Luna y Jesus Mendoza

## Contexto

ADR-0005 definió el registro de visitante en 3 pasos secuenciales: INE,
Rostro y Confirmación. Ese último paso (`ConfirmDataView`) era un
formulario donde el visitante escribía a mano el motivo de la visita y
la casa/depto destino en campos de texto libre, y presionaba "Solicitar
acceso" sin ninguna confirmación visual de qué pasaba después — el
único feedback era un diálogo genérico de "espera la aprobación del
residente".

Esto tenía tres problemas:

1. El motivo y la casa destino dependían de que el visitante escribiera
   correctamente, sin ninguna validación contra datos reales — una casa
   mal escrita podía hacer que la solicitud le llegara al residente
   equivocado o a ninguno.
2. El backend ya tenía un modelo `Destino` (casa/depto + titular) por
   kiosko, pero el formulario no lo consultaba: el visitante tecleaba el
   destino en vez de elegirlo de una lista real.
3. El visitante no tenía forma de saber si su solicitud fue aceptada o
   rechazada una vez enviada.

Al construir la extensión se encontraron además 4 bugs preexistentes que
bloqueaban cualquier prueba real del flujo, ninguno pedido explícitamente
pero necesarios como prerrequisito:

- `KioskoServicio` llamaba a `POST /auth/acceso/login`,
  `GET /accesos/:id/destinos/` y `POST /accesos/:id/visitas/` — rutas que
  ya no existen. Son resabio de un rename `acceso` → `kiosko` en el
  backend (migración `000013_rename_acceso_to_kiosko`) que nunca se
  propagó al Flutter. El login fallaba con 404 antes de llegar a
  cualquier otra cosa.
- El body de login enviaba `acceso_id` en vez de `kiosko_id`, el nombre
  de campo que espera `LoginKioskoRequest`.
- El campo `Placa` en `VisitaRequest` (backend) estaba marcado
  `binding:"required"` en Go a pesar de que su propia documentación
  Swagger y el modelo de base de datos lo tratan como opcional. El nuevo
  flujo no captura placa, así que sin este fix cada solicitud nueva
  regresaría 400.
- No existía ninguna forma de que el kiosko (sesión de kiosko, no JWT de
  admin) consultara el estado de la visita que acababa de crear:
  `GET /visitas/:id` y el stream SSE `/kioskos/solicitudes/stream`
  requieren JWT de admin.

## Decisión

### Dos pasos nuevos de selección guiada, no texto libre

Se agregaron `MotivoVisitaView` y `CasaDestinoView` entre Rostro y el
resumen final:

- **Motivo**: lista fija de 4 opciones definidas en el propio Flutter
  (`motivo_visita_model.dart`) — Paquetería o proveedor, Visita familiar
  o social, Servicio técnico, Otro. No viene de la base de datos; no hay
  endpoint de "motivos" en el backend.
- **Casa destino**: lista de los `Destino` reales del kiosko, obtenida
  de `GET /api/v1/kioskos/:id/destinos/` (endpoint que ya existía en el
  backend, solo faltaba consumirse correctamente desde Flutter).

Ambas son pantallas de un solo tap: no se integraron al
`currentStep`/`steps` de `TouchRegisterViewModel`, porque esa estructura
es específica de la UI de "botón circular que abre cámara" de los pasos
INE/Rostro (`nextStep()` ni siquiera puede avanzar más allá del índice
1). En vez de eso siguen el mismo patrón que ya usan los pasos de
cámara: `Navigator.push<String>` → await → `Navigator.pop(valor)`, y su
`StepIndicator` usa valores fijos (`currentStep: 2`/`3`, `totalSteps: 5`)
en vez de leer el ViewModel — igual que ya hacía `ConfirmDataView` con
`StepIndicator(currentStep: 2, totalSteps: 3)`.

El único cambio en `TouchRegisterViewModel` fue `indicatorTotalSteps` de
`3` a `5`. **Esta decisión reemplaza formalmente la de ADR-0005**
(3 pasos); ADR-0005 queda marcado como superseded por este documento.

Si el visitante presiona "atrás" en Motivo o Casa, se cancela toda la
solicitud (`popUntil` a la raíz del wizard) en vez de intentar reanudar
un paso intermedio — no existe una pantalla razonable a la que volver
desde ahí.

### Endpoint de solo consulta para el estado — polling, no WebSockets/SSE

Se agregó `GET /api/v1/kioskos/:id/visitas/:visitaId` (autenticado con
sesión de kiosko vía el helper `kioskoSesionAutorizada`, que ya usaba
`RegisterVisita`; responde con el mismo DTO `VisitaResponse` que ya
devolvía la creación).

Se descartó extender el hub de SSE existente (`/kioskos/solicitudes/stream`,
hoy exclusivo del dashboard admin) por dos razones:

1. `internal/platform/sse/hub.go` hace `Broadcast` a todos los clientes
   conectados sin filtrar por kiosko. Simplemente cambiar el middleware
   para aceptar sesión de kiosko filtraría las visitas de **todos** los
   kioskos a cualquiera que se conectara — una fuga de datos entre
   kioskos, no solo un problema de permisos.
2. Ni siquiera resolvería el problema: `ActualizarEstado` (aprobación o
   rechazo manual desde el dashboard, ver ADR-0013 del backend) nunca
   hace `Broadcast`. Solo el análisis automático de IA lo hace, y
   únicamente para los estados `PENDIENTE`/`REVISION`, nunca para los
   estados terminales `APROBADO`/`RECHAZADO` que son justo los que le
   importan al visitante.

`ResumenSolicitudView` consulta este endpoint cada 3 segundos
(`Timer.periodic`) mientras el estado es `PENDIENTE`/`REVISION`. Es el
mismo criterio de simplicidad que ya se usó en ADR-0013 del backend para
el lado del dashboard (polling de 15s en vez de tiempo real), con un
intervalo más corto porque aquí es un solo visitante esperando su propio
resultado, no una lista completa refrescándose.

### Pantalla de resumen de solo lectura + espera, reemplaza el formulario

`ResumenSolicitudView` reemplaza por completo a `ConfirmDataView` (se
borró el archivo). Ya no hay campos de texto: motivo y casa se
capturaron en los pasos anteriores, así que al entrar a esta vista se
llama `registrarVisitante(...)` de inmediato, sin que el usuario
presione ningún botón para enviar.

Muestra una animación de carga (`LoadingIndicator`, el mismo paquete que
ya usa el botón de voz de `TouchRegisterView`) mientras el estado es
`PENDIENTE`/`REVISION`, y debajo un resumen de solo lectura: foto de
rostro capturada localmente (`Image.file`, no se espera a la URL del
servidor), nombre, hora de solicitud, motivo y casa. Al llegar a estado
terminal, la animación se reemplaza por un ícono de resultado (
aprobado / rechazado).

Decisión tomada durante las pruebas del flujo ya construido: en vez de
un botón "Finalizar" manual, la vista espera 1 minuto en el estado
terminal y regresa sola a la pantalla de bienvenida (`popUntil` a la
raíz). Es necesario porque este es hardware de kiosko sin atención
humana constante — debe quedar listo para el siguiente visitante sin
depender de que alguien presione un botón. Se aplica igual a aprobación
y a rechazo: si solo aplicara a la aprobación, una solicitud rechazada
dejaría el kiosko atorado sin ninguna forma de continuar.

## Consecuencias

Positivas:

- El motivo y la casa destino ya no dependen de que el visitante escriba
  texto libre correctamente.
- La casa destino sale de datos reales del condominio (`destinos`), no
  de lo que el visitante teclee.
- El visitante recibe una señal visual clara de si su acceso fue
  aceptado o no.
- Se corrigieron 4 bugs preexistentes que bloqueaban cualquier prueba
  real de la app (3 rutas rotas por el rename `acceso`→`kiosko`, más el
  campo `placa` obligatorio en el backend), no solo lo pedido
  explícitamente.
- El endpoint nuevo es mínimo — una consulta de solo lectura que
  reutiliza DTOs y helpers ya existentes — y no requiere tocar la
  infraestructura de SSE ni el dashboard admin.

Negativas / Trade-offs:

- El polling de 3s significa que, en el peor caso, el visitante puede
  tardar hasta 3 segundos de más en enterarse de que ya fue aprobado.
  Aceptable porque la aprobación en sí normalmente tarda mucho más que
  eso (el residente o admin tiene que reaccionar primero).
- `KioskoServicio` se instancia de nuevo en cada vista nueva
  (`CasaDestinoView`, `ResumenSolicitudView`) en vez de compartir una
  sola sesión — cada visitante ahora genera 2 logins de kiosko en vez de
  1, y cada login crea una fila nueva en `sesion_kioskos` sin expiración
  automática (solo se revocan manualmente desde el admin). Es un
  problema preexistente en el mismo archivo que esta extensión agrava
  pero no introdujo; no se resolvió aquí.
- El regreso automático de 1 minuto es un valor fijo en código, no
  configurable desde el dashboard admin — a diferencia de otros tiempos
  de espera del kiosko (ver ADR-0011 del backend, `tiempo_espera_min`).
- ADR-0005 queda obsoleto en la parte de "3 pasos" y
  `StepIndicator(totalSteps: 3)` — cualquier referencia futura a ese
  ADR debe consultar también este.
