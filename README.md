# 🚗 AUTOnomIA

Kiosko de auto-registro de visitantes para fraccionamientos privados. Desarrollado para el **Reto de Industria FEPRO 2026 — BUAP y Kigo** por el equipo *Zero Devs*.

## 📌 El Sistema en Breve

- El **visitante se registra** de forma autónoma en la tablet de la caseta — OCR de INE y validación facial totalmente en dispositivo, sin APIs de visión externas.
- La **IA evalúa la visita** contra el historial de esa persona y la aprueba sola si es de confianza; si detecta anomalías la manda a revisión. Un LLM local (`llama.cpp`) redacta el resumen de seguridad.
- El **vigilante supervisa** el proceso desde un dashboard web en tiempo real (SSE) y todo queda en una bitácora auditable.
- El **residente** gestiona sus invitaciones QR desde su app, recibe notificaciones push (FCM) y puede aprobar o rechazar visitas pendientes directamente desde el teléfono.
- Los **kioskos se activan** sin contraseñas: el dispositivo genera un código corto que el admin aprueba desde el dashboard (RFC 8628).

---

## 🏗️ Arquitectura del Monorepo

```text
autonomia/
├── backend/     API REST en Go — Fuente de verdad del sistema.
├── kiosko/      App Flutter — Terminal para la caseta de vigilancia.
└── kigo-app/    App Flutter — Aplicación móvil para el usuario final (residente).
```

- **Backend:** Go 1.26, Gin, GORM y PostgreSQL 16. Incluye migraciones automáticas, dashboard admin (`/admin`) y documentación Swagger (`/swagger/index.html`). Desplegado vía Docker Compose y expuesto al exterior con **Tailscale Funnel** en el puerto `10000`.
- **Kiosko:** Flutter (Android). Flujo de registro en 3 pasos con OCR on-device (MLKit) para escaneo de INE y validación facial (MobileFaceNet / TFLite). Todo corre localmente sin APIs de IA externas. Se activa con un código corto que el admin aprueba desde el dashboard (RFC 8628). Incluye asistente de voz TTS/STT ("Kigo").
- **Kigo App:** Flutter (Android/iOS). Auto-registro con el código de la instalación, onboarding biométrico (face enrollment), login con PIN, generación y compartición de invitaciones QR personales o grupales, y aprobación/rechazo de visitas pendientes mediante **notificaciones push (FCM)**.

---

## ⚙️ Configuración del Entorno Local

### 1. Backend

Requiere **Go 1.21+** y **PostgreSQL**, o bien **Docker + Docker Compose**.

```bash
cd backend
cp .env.example .env
# Edita .env: credenciales de BD, JWT_SECRET, etc.
go run cmd/server/main.go
```

El servidor inicia en `http://localhost:8000` con migraciones automáticas.

> **Con Docker Compose:**
> ```bash
> cd backend
> docker compose up --build
> ```
> El servicio queda expuesto en `http://localhost:10000` (mapeo `10000→8080` para compatibilidad con Tailscale Funnel).

### 2. Kiosko

Requiere Flutter 3.x y un dispositivo Android conectado (USB / Depuración inalámbrica).

```bash
# Redirección de puertos para pruebas locales en dispositivo físico:
adb reverse tcp:8000 tcp:8000

cd kiosko
flutter pub get
flutter run
```

> La URL del backend se configura en `lib/core/config/kiosko_config.dart`.

### 3. Kigo App (residente)

```bash
cd kigo-app
flutter pub get
flutter run
```

> La URL del backend se configura en `lib/services/api_service.dart`.

---

## 📡 Documentación API (Swagger)

Con el backend activo, accede a la documentación interactiva en:
👉 `http://localhost:8000/swagger/index.html`

### Endpoints Críticos

| Método | Ruta | Descripción |
| :--- | :--- | :--- |
| POST | `/api/v1/auth/login` | Autenticación de administrador (JWT) |
| POST | `/api/v1/auth/device/authorize` | El kiosko pide un código de activación (RFC 8628) |
| POST | `/api/v1/auth/device/token` | El kiosko canjea el código por su sesión |
| POST | `/api/v1/auth/kiosko/login` | Re-autenticación del kiosko (token de sesión) |
| GET | `/api/v1/device/pending` | Lista de kioskos pendientes de aprobación |
| POST | `/api/v1/device/:user_code/aprobar` | Admin aprueba la activación del kiosko |
| POST | `/api/v1/kioskos/` | Crear punto de entrada |
| POST | `/api/v1/kioskos/:id/visitas/` | Registrar visita (Kiosko) |
| GET | `/api/v1/kioskos/solicitudes/stream` | Feed en tiempo real SSE (Admin) |
| GET | `/api/v1/kioskos/:id/config/stream` | Config SSE en tiempo real (Kiosko) |
| GET | `/api/v1/centros/:codigo/destinos` | Destinos de una instalación (público) |
| POST | `/api/v1/centros/:codigo/residentes/auto-registro` | Alta de residente (queda pendiente) |
| POST | `/api/v1/centros/:codigo/residentes/login` | Login de residente con PIN |
| GET | `/api/v1/residentes/me/visitas/pendientes` | Visitas pendientes de aprobación (Residente) |
| PATCH | `/api/v1/residentes/me/visitas/:id/estado` | El residente aprueba o rechaza una visita |
| POST | `/api/v1/residentes/me/invitaciones` | Crear invitación QR |
| POST | `/api/v1/personas/registro/solicitar-otp` | Solicitar OTP de verificación telefónica |
| POST | `/api/v1/personas/registro/verificar-otp` | Verificar OTP y crear/recuperar `Persona` |
| GET | `/api/v1/personas/me/qr` | QR de identidad del residente |

Para regenerar la documentación tras modificar handlers:

```bash
cd backend
go tool swag init -g cmd/server/main.go --parseInternal -o docs
```

---

## 🧠 Decisiones Técnicas

Las justificaciones de arquitectura (ADRs) están documentadas en:

- [`/backend/docs/adr/`](backend/docs/adr/adr_README.md) — Decisiones del servidor: stack, autenticación por interfaz, multi-tenant, activación de kioskos.
- [`/docs/adr/`](docs/adr/README.md) — Decisiones que cruzan subproyectos, como el sistema de diseño unificado.
- [`/kiosko/docs/`](kiosko/docs/) — Notas de implementación de la app del kiosko.

---

## 👥 Equipo (Zero Devs)

Facultad de Ciencias de la Computación, BUAP.

- Jose de Jesus Mendoza Reyes
- Jose Alberto Luna Santos
- Ivan Ramses Ramirez Perez
- Leonardo Lagos Lopez
