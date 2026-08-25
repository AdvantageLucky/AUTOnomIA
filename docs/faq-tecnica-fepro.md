# FAQ técnica — preparación para FEPRO / Kigo

Respuestas cortas y honestas a las preguntas que pueden hacernos jueces o el equipo de Kigo
sobre las decisiones técnicas de AUTOnomIA. Cada sección: qué es, por qué lo elegimos, y qué
responder si nos aprietan con el "¿y por qué no X?".

---

## Arquitectura general

**¿Qué es el sistema?**
Un backend Go (Gin + GORM + PostgreSQL) como única fuente de verdad, un dashboard web que el
propio backend sirve en `/admin`, y dos apps Flutter (kiosko y residente) que hablan con la API
por HTTP REST. La IA de scoring corre en el servidor (llama.cpp); el ML de visión (OCR de INE,
detección de rostro) corre **en el dispositivo** del kiosko con MLKit, sin APIs externas.

```
PostgreSQL ◄── backend Go ──► llama.cpp (scoring, async)
                  │ sirve /admin
                  ▼
     dashboard web (vanilla JS) ── JWT admin + SSE
     app kiosko  ── token de sesión opaco + SSE config
     app residente ── JWT residente (solo pull)
```

**¿Por qué el dashboard es vanilla y no React?**
Un solo `index.html` + `app.js` + `styles.css`, sin bundler. Decisión deliberada (ADR 0009/0010):
cero dependencias de build, se sirve directo desde el binario Go, y el equipo lo puede depurar con
el inspector del navegador sin toolchain. Para el alcance de un panel de administración es
suficiente; si creciera a decenas de vistas, reconsideraríamos.

**¿Por qué Flutter?**
Un solo código para las dos apps (kiosko Android y residente Android/iOS), buen soporte de cámara
y MLKit, y el equipo ya lo conocía.

---

## Multi-tenant

**¿Qué significa que el sistema es multi-tenant?**
Una sola instalación (un backend, una base de datos) sirve a varios clientes independientes. Cada
`CentroHabitacional` (fraccionamiento, plaza, campus…) es un *tenant*. Comparten servidor y
tablas, pero sus datos están aislados: un admin solo ve sus kioskos, residentes y visitas.

**¿Cómo se aísla?**
Por columna discriminadora: toda tabla de dominio tiene `tenant_id` (migración 000025). El
middleware de auth extrae el tenant del JWT o de la sesión del kiosko y lo inyecta en el contexto;
los repositorios aplican scopes de GORM que añaden `WHERE tenant_id = ?`. Para consultas con JOIN
usamos `ByTenantFor(tabla)`, que califica la columna (`visitas.tenant_id`) para evitar ambigüedad
SQL (ADR 0021).

**¿Cada admin es un tenant?**
Cada admin *dueño* crea su propio `CentroHabitacional` al registrarse. Los vigilantes que ese
admin da de alta heredan su tenant (no crean uno).

**¿Y si un programador olvida el filtro en una consulta nueva?**
Respuesta honesta: hoy esa consulta vería datos de todos los tenants. El aislamiento vive en el
código, no en la base de datos. La mitigación conocida es **Row-Level Security de PostgreSQL**:
políticas en la BD que filtran filas por tenant aunque el código olvide el `WHERE`
(`CREATE POLICY ... USING (tenant_id = current_setting('app.tenant_id'))`). Está en el roadmap;
no lo implementamos aún porque exige propagar el tenant a nivel de conexión y el alcance de FEPRO
priorizó funcionalidad. Sabemos exactamente cómo añadirlo.

**¿Por qué no una base de datos por cliente?**
Costo operativo: N bases = N migraciones, N backups, N conexiones. El modelo de columna
discriminadora es el estándar SaaS (Slack, Shopify empezaron así) y escala hasta muy tarde.

---

## Autenticación (hay tres, y es a propósito)

Principio: **menor privilegio por tipo de interfaz** (ADR 0004).

| Actor | Mecanismo | Por qué |
|---|---|---|
| Admin / vigilante | JWT (HS256, 24 h), login con correo/contraseña o Google | Humano con sesión corta; stateless, no toca BD por request |
| Kiosko | **Token de sesión opaco persistido en BD** | Dispositivo desatendido que debe poder **revocarse al instante** desde el dashboard (JWT no se puede revocar sin lista negra) |
| Residente | JWT (7 días), login con código de instalación + casa + PIN | Usuario final no técnico; el PIN (bcrypt) minimiza fricción |

**¿JWT vs token opaco — por qué los dos?**
JWT: el servidor no guarda nada, verifica la firma; ideal para humanos con sesiones cortas.
Opaco en BD: cada request consulta la tabla `sesion_kioskos`; más costoso pero **revocable** — al
eliminar un kiosko robado, su siguiente petición recibe 401 y el dispositivo vuelve solo a la
pantalla de activación.

**¿Los PINs están en claro?**
No. bcrypt (hash adaptativo con salt). Igual las contraseñas de admin y la clave de kiosko.

---

## Activación del kiosko (RFC 8628)

**¿Qué es eso del código de 8 letras?**
El *OAuth 2.0 Device Authorization Grant* — el mismo flujo con el que una smart TV te hace teclear
un código en el teléfono. El kiosko pide un código (`XXXX-XXXX`), lo muestra con QR, y hace polling
cada 5 s mientras el admin lo escribe y aprueba en el dashboard. Al aprobarse, el kiosko recibe su
sesión (ADR 0019).

**¿Por qué así y no teclear una clave en el kiosko?**
Invertimos la dirección: el secreto largo nunca se transcribe a mano ni se muestra al humano; el
código corto se teclea donde hay teclado real. El código expira en 15 min, usa charset sin vocales
(no forma palabras) y exige un admin autenticado para aprobarse.

**Debilidad conocida:** el endpoint de polling es público y sin rate limiting. Adivinar el
`device_code` (32 bytes aleatorios) es impracticable, pero limitaríamos la tasa antes de producción.

---

## Comunicación en tiempo real

Solo hay **tres** mecanismos vivos; todo lo demás es request/response:

1. **SSE dashboard** (`/kioskos/solicitudes/stream`): las solicitudes nuevas aparecen sin refrescar.
2. **SSE config del kiosko** (`/kioskos/:id/config/stream`): cambiar tema/idioma/fotos desde el
   dashboard se aplica en caliente en el dispositivo.
3. **Polling del kiosko tras registrar visita** (cada 3 s): espera el veredicto
   (APROBADO/RECHAZADO/REVISION) para mostrarlo al visitante.

**¿Por qué SSE y no WebSockets?**
El flujo es unidireccional (servidor → cliente). SSE es HTTP plano: pasa por cualquier proxy,
reconecta solo, y no necesita protocolo propio. WebSockets se justificaría con tráfico
bidireccional, que hoy no tenemos (el ADR 0014 lo dejó previsto si hiciera falta).

**¿La app residente recibe notificaciones push?**
**No todavía.** Hoy el residente solo consulta al abrir la app (pull). El flujo "el residente
aprueba la visita desde su teléfono" está diseñado pero no implementado: requiere FCM (Firebase
Cloud Messaging), guardar el token del dispositivo por residente, un vínculo visita→residente que
hoy no existe (la casa es un string, no una FK), y un estado nuevo de visita ("esperando
residente"). Es la siguiente fase del roadmap y lo decimos tal cual si preguntan.

---

## La IA

**¿Qué hace exactamente?**
Dos cosas separadas que no hay que confundir:

1. **Visión on-device (kiosko):** OCR de la INE y detección de rostro con Google MLKit, corriendo
   en el dispositivo. Nada sale a APIs externas — privacidad y funcionamiento sin latencia de red.
   El OCR corrige confusiones típicas (O↔0, I↔1) apoyándose en la estructura fija de la CURP.
2. **Scoring en servidor:** al registrar una visita, una goroutine (timeout 2 s) evalúa el
   historial de ese CURP (recurrencia, anomalías de placa, horario inusual, rechazos previos) y un
   LLM local vía llama.cpp genera el resumen. Resultado: auto-aprobar, mandar a revisión, o dejar
   pendiente para el vigilante.

**¿Por qué llama.cpp local y no OpenAI/Claude?**
Datos personales (INE, CURP, rostros) no salen de nuestra infraestructura; costo cero por
inferencia; funciona sin internet. El trade-off es capacidad del modelo, aceptable porque el LLM
solo redacta resúmenes — el scoring es lógica determinista.

**¿El autopass es seguro?**
Solo aprueba si: historial confiable (umbral configurable por kiosko) **y** cero anomalías **y**
el admin tiene autopass habilitado. Cualquier anomalía → revisión humana. Y todo queda en
bitácora auditable con foto.

---

## Base de datos

**¿Por qué PostgreSQL?**
Relacional (el dominio es relacional: tenants→kioskos→visitas), soporte de RLS para el roadmap de
aislamiento, y es el estándar que Kigo puede operar.

**¿Migraciones?**
Versionadas con archivos SQL numerados (`000001`–`000030`), up/down, aplicadas con golang-migrate.
Nada de auto-migrate de GORM en producción: queremos control exacto del esquema.

**¿Borrado de datos?**
Soft-delete (columna `deleted_at`) en todo el dominio: la bitácora es auditable, nada se destruye.

---

## Puntos débiles que admitimos si preguntan

Decir esto con franqueza da más credibilidad que esconderlo:

- **Sin RLS**: el aislamiento multi-tenant depende del código; una consulta sin scope fugaría
  datos. Roadmap claro para añadirlo.
- **Sin rate limiting** en el endpoint público de activación de kioskos.
- **Sin push al residente**: su rol de aprobar visitas está diseñado, no construido.
- **Sin CI**: los checks (build, tests, analyze) corren a mano, no en cada push.
- **PIN por casa sin unicidad forzada**: dos residentes de la misma casa con el mismo PIN
  colisionarían (el login resuelve al primero).
- **URLs del backend hardcodeadas** en las apps para el entorno de demo.
- **Sin modo offline en el kiosko**: si se cae la red, el kiosko no registra (roadmap: cola local
  SQLite con sincronización).

---

## Chuleta de siglas

- **Tenant / multi-tenant**: cliente aislado dentro de una instalación compartida.
- **RLS**: Row-Level Security — Postgres filtra filas por política, aunque el código olvide el WHERE.
- **JWT**: token firmado autocontenido; el servidor no guarda sesión.
- **Token opaco**: cadena aleatoria que solo significa algo consultando la BD; revocable.
- **SSE**: Server-Sent Events — el servidor empuja eventos por una conexión HTTP abierta.
- **RFC 8628**: Device Authorization Grant — activación de dispositivos sin teclado con código corto.
- **bcrypt**: hash adaptativo para contraseñas/PINs, con salt y costo configurable.
- **FCM**: Firebase Cloud Messaging — push a móviles (pendiente de integrar).
- **MLKit**: ML de Google on-device (OCR, rostros); no manda datos a la nube.
- **Soft-delete**: marcar como borrado (`deleted_at`) sin destruir la fila.
- **GORM scope**: función reutilizable que añade condiciones a una consulta (así inyectamos el tenant).
