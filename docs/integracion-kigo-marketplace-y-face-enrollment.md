# Integraciones con Kigo — Marketplace SDK y Face Enrollment API

Referencia técnica de dos servicios de terceros que **Kigo** (no nosotros) provee, para una
mini-app de AUTOnomIA embebida dentro de la app **Kigo Parkimovil**, más el plan de integración
acordado hasta ahora (2026-08-25/26). Este documento describe qué hace cada servicio, qué NO
hace, y el flujo propuesto — varias suposiciones iniciales sobre ambos no se sostuvieron al
revisar el código/documentación real, y quedan anotadas para no repetir la confusión.

No es un ADR: no hay todavía una decisión de arquitectura formalizada, solo el mapa de lo que
estos servicios ofrecen y el plan en construcción. Cuando el plan se cierre, esa decisión sí va
a un ADR nuevo (probablemente en `docs/adr/`, por cruzar kiosko + backend + una mini-app nueva).

## 1. `@kigo-dev/marketplace-sdk`

npm: https://www.npmjs.com/package/@kigo-dev/marketplace-sdk (versión revisada: `0.8.0`)
Repo: https://github.com/Parkimovil/kigo-marketplace-sdk

SDK de JavaScript/TypeScript para integrar una "mini-app" web dentro del contenedor nativo de
Kigo (en este caso, Kigo Parkimovil). Expone un puente (`bridge`) JS ↔ nativo: la mini-app corre
en un WebView dentro de la app de Kigo, y llama a capacidades nativas a través de `kigo.*`.

**No corre en un navegador normal** — requiere el bridge nativo. Para desarrollo local trae un
"Playground" que simula el comportamiento nativo (`npm run dev`).

### Módulos y qué exponen

| Módulo | Qué da | Relevante para nosotros |
|---|---|---|
| `kigo.auth` | `kigo.auth.init()` → `{ sessionId, userId, expiresAt }` | **Solo esto.** Confirmado en el FAQ del propio README ("How do I know which user is using my app? → call kigo.auth.init()"). Ni teléfono, ni nombre, ni correo — para eso, la mini-app pide sus propios datos (ver sección 3) |
| `kigo.payments` | Checkout nativo, consulta de status, auto-recarga (solo últimos 4 dígitos + marca) | No aplica a control de acceso, mencionado por completitud |
| `kigo.navigation` | `close()`, `openExternal()`, `setBackVisible()`, `onBack()` | `close()` es cómo la mini-app termina y regresa al marketplace de Kigo |
| `kigo.ui` | `toast()`, `confirm()`, `setTitle()` | Componentes nativos para mantener consistencia visual con la app de Kigo |
| `kigo.device` | `getContext()` → tema, locale, plataforma, `safeArea`, tamaño de pantalla | Útil para respetar el "notch"/safe area del dispositivo host |
| `kigo.location` | `getCurrent()` → lat/long | No aplica a este caso de uso |
| `kigo.media` | `pickFromGallery()`, `capturePhoto()` — cámara/galería nativas, base64 con EXIF/GPS ya removido | Alternativa a Face Enrollment si quisiéramos capturar la foto nosotros — pero **no hace liveness check**, solo toma una foto |
| `kigo.storage` | `set/get/remove` de strings u objetos JSON, aislado por mini-app | Persistencia ligera del lado cliente |
| `kigo.analytics` | `track({ event, properties })` | — |
| `kigo.devtools` | Consola de depuración con overlay, intercepción de `fetch`, diagnóstico de foco en iOS WebView | Solo desarrollo |

**Confirmado (no es una suposición): el SDK no da teléfono ni nombre del usuario, en ningún
módulo.** Icono de la mini-app y teléfonos de contacto tampoco son parte del SDK — son metadata
de registro en el panel/marketplace de Kigo, separado del paquete npm.

## 2. Face Enrollment API (Kigo Verify)

Servicio HTTP aparte (no es parte del SDK de arriba). Colección Postman entregada por Kigo con
credenciales reales de dev — **el archivo vive localmente como `/api` en la raíz del repo,
ignorado por `.gitignore` (verificar que la entrada siga ahí después de cualquier `git reset`
sobre commits que la toquen), nunca se sube.**

Base URL: `https://verify-api.kigo.dev`. Auth: header `x-api-key` (fija el proyecto — Fepro en
este caso — así que `project_id` no se manda en el cuerpo).

### Qué hace, en una frase

Verificación remota de identidad por selfie con **liveness check** (confirma que hay una
persona real frente a la cámara, no una foto de una foto ni un video/máscara), completada por
el usuario en su propio teléfono a través de un link web.

### Flujo

```
1. POST /v1/enrollments           (nuestro backend)
   → { enrollment_id, enrollment_url, webhook_secret (una sola vez) }

2. Se le manda enrollment_url al usuario (dentro de la mini-app, con webview embebido)

3. El usuario hace el liveness check ahí mismo

4. Nuestro webhook_url recibe "EnrollmentCompleted"
   con external_ref, metadata (tal cual la mandamos) y photo_url
```

### `POST /v1/enrollments` — crear

```jsonc
{
  "external_ref": "FEPRO-0042",     // nuestro ID, vuelve en el webhook para reconciliar
  "webhook_url": "https://...",      // debe responder 2xx; un 404 se reintenta ~15h y muere
  "redirect_url": "https://...",     // opcional, a dónde regresa el navegador al terminar
  "ttl_hours": 24,                   // 1..72, default 24
  "metadata": { ... }                // JSON libre, Kigo NO lo interpreta, solo lo guarda y regresa
}
```

Responde `enrollment_id`, `enrollment_url`, `status: "PENDING"`, `expires_at`, y
`webhook_secret` (solo esta vez, no se vuelve a mostrar).

**`delivery_channel` (WHATSAPP/SMS/EMAIL) existe en el schema pero está roto**: el evento de
despacho interno de Kigo sale con `recipient_ref` vacío, hardcodeado en su código (confirmado
en su código fuente, no en su documentación). No aplica de todos modos a nuestro flujo — el
`enrollment_url` se abre directo dentro de la mini-app, no se manda por fuera.

### `GET /v1/enrollments/{id}` — consultar estado

Estados observados: `PENDING` → `CONSENT_GIVEN` → `LIVENESS_STARTED` → `LIVENESS_COMPLETED` →
`COMPLETED`, o terminales de falla `LIVENESS_FAILED` / `QUALITY_FAILED`. Trae también
`liveness_retries` y `liveness_confidence` (0.0–1.0).

**Advertencia de estabilidad (encontrada en pruebas manuales, 2026-08-25):** de 5 enrolamientos
de prueba creados, 1 llegó a `QUALITY_FAILED` tras 2 reintentos y **2 quedaron atorados
indefinidamente en `LIVENESS_STARTED`** con `liveness_confidence` ya calculado, sin pasar nunca
a un estado terminal — probados con navegador nativo del celular y wifi estable, lo que
descarta las causas más comunes de este tipo de falla. Pendiente reportarlo a Kigo con los
`enrollment_id` si se repite una vez integrado en la mini-app real.

### `GET /v1/enrollments/{id}/photo` — descargar la foto

Devuelve el JPEG directo. 404 hasta que el estado sea `COMPLETED`. Misma URL que llega como
`photo_url` en el webhook.

### `GET /v1/enrollments?limit=20` — listar

Todos los enrolamientos del proyecto, con estado + `photo_url` + `metadata` verbatim.

### Lo que este servicio NO hace

**No hay endpoint de comparación/verificación de un rostro contra otro** — solo enrola y
entrega una foto (`photo_url`). Cualquier comparación 1:N contra rostros ya registrados la
hacemos nosotros. Ver sección 3.

## 3. Plan de integración (en construcción, 2026-08-26)

### Flujo de la mini-app

```
1. Mini-app arranca dentro de Parkimovil, llama kigo.auth.init() → userId

2. GET /api/v1/personas/por-kigo-user-id/:userId   (nuevo endpoint)
   → 200 si ya existe una Persona vinculada a ese userId → listo, no repetir wizard
   → 404 si es la primera vez → sigue al paso 3

3. Wizard de alta (mismo que ya existe para auto-registro, ver ADR-0020), adaptado:
   - correo
   - teléfono          (se pide aquí porque el SDK NO lo da — ver sección 1)
   - OTP AL CORREO      (no SMS: incluso con el teléfono ya en mano, no hay forma de
                          confirmarlo por SDK, así que la verificación de identidad real
                          sigue siendo el correo — el teléfono queda como dato de contacto,
                          no verificado por OTP)
   - nombre
   - cara → Kigo Face Enrollment (sección 2): se crea el enrollment, se abre
     enrollment_url dentro de la mini-app, se espera el webhook

4. Al recibir EnrollmentCompleted en nuestro webhook:
   - descargar la foto (GET .../photo)
   - calcular su embedding facial            ⚠️ ver "Riesgo central" abajo
   - crear/actualizar la Persona: kigo_user_id, correo, teléfono, nombre, embedding
```

### Comparación en el kiosko

Sin cambios de arquitectura: el kiosko ya tiene el flujo completo de comparación 1:N para
acceso de residente por rostro —

- `kiosko/lib/features/residente/services/reconocimiento_facial_servicio.dart` calcula el
  embedding de la foto tomada en vivo (modelo **MobileFaceNet** vía TFLite, on-device,
  192 dimensiones).
- `POST .../verificar-rostro` → `backend/internal/domain/residente/handlers.go
  VerificarRostroDesdeKiosko` trae todos los candidatos activos con embedding del tenant
  (`FindActivosConEmbeddingPorTenant`) y llama `mejorCoincidencia`
  (`backend/internal/domain/residente/matching.go`), que hace **cosine similarity** contra
  cada uno y regresa el mejor score.

Para que un residente enrolado vía la mini-app sea reconocible en el kiosko, su fila necesita
el mismo tipo de campo `Embedding []float64` que ya usan los residentes dados de alta por otras
vías — la comparación en sí no cambia.

### ⚠️ Riesgo central: el embedding del enrollment de Kigo no se calcula solo

Kigo Verify entrega una **foto** (`photo_url`), no un embedding. El backend hoy **nunca calcula
embeddings** — solo los guarda y compara (`Embedding []float64` ya viene calculado por el
cliente que lo manda). El único lugar del proyecto que sabe correr MobileFaceNet es el kiosko
Flutter, on-device, vía el asset `assets/models/mobilefacenet.tflite`.

Eso significa que "todo seguiría casi igual" (como se planteó inicialmente) **no es exacto** —
falta decidir quién calcula el embedding de la foto de Kigo, con dos caminos:

1. **La mini-app lo calcula en el navegador** (ej. portando MobileFaceNet a TensorFlow.js u
   ONNX.js) justo después de que el webhook confirme `COMPLETED`, y manda el embedding ya
   calculado al backend — mismo patrón que ya usa el kiosko (el cliente calcula, el servidor
   solo guarda/compara). Consistente con la arquitectura actual, pero exige portar el modelo a
   JS y validar que produzca vectores comparables 1:1 con los que genera la versión TFLite.
2. **El backend lo calcula** — necesitaría un binding de TFLite en Go, o un microservicio
   aparte (ej. Python) que descargue `photo_url` y corra el mismo modelo. Rompe el patrón
   "el servidor nunca ve/calcula embeddings", pero centraliza el versionado del modelo en un
   solo lugar en vez de dos runtimes (Flutter + navegador) que tienen que mantenerse en
   sincronía exacta.

**Sin resolver esto, la comparación en el kiosko simplemente no tiene con qué comparar** — es
la pieza que decide si el plan funciona, no un detalle de implementación tardío.

## Preguntas abiertas (sin resolver aún)

- ¿Quién calcula el embedding de la foto de Kigo Verify — la mini-app (browser) o el backend?
  (ver "Riesgo central" arriba)
- Si es la mini-app: ¿MobileFaceNet tiene un port confiable a TensorFlow.js/ONNX.js, o hace
  falta reentrenar/exportar el modelo a un formato distinto?
- ¿A quién y cómo se reporta la inestabilidad de `LIVENESS_STARTED` que no cierra en Kigo
  Verify?
- Migración de backend: nuevo campo `kigo_user_id` en `Persona` (o tabla de vínculo aparte si
  una Persona puede tener más de una fuente de identidad externa) + el endpoint
  `GET /api/v1/personas/por-kigo-user-id/:userId`.
- Confirmar con Kigo si existe algún endpoint de perfil (nombre/teléfono) a partir del
  `userId` fuera de este SDK — si existe, el wizard de correo/teléfono/OTP podría acortarse.
