# 🚗 AUTOnomIA

Kiosko de auto-registro de visitantes para fraccionamientos privados. Desarrollado para el **Reto de Industria FEPRO 2026 — BUAP y Kigo**.

## 📌 El Sistema en Breve
- El **visitante se registra** de forma autónoma en la tablet de la caseta.
- La **IA evalúa la visita** contra el historial de esa persona y la aprueba sola si es de confianza; si detecta anomalías la manda a revisión.
- El **vigilante supervisa** el proceso desde un dashboard web en tiempo real (SSE) y todo queda en una bitácora auditable.
- El **residente** gestiona sus invitaciones QR desde su teléfono.

> La aprobación de visitas por parte del residente mediante notificaciones push está en diseño, no implementada.

---
## 🏗️ Arquitectura del Monorepo

```text
autonomia/
├── backend/     API REST en Go — Fuente de verdad del sistema.
├── kiosko/      App Flutter — Terminal para la caseta de vigilancia.
└── residente/   App Flutter — Aplicación móvil para el usuario final.
```
- **Backend:** Go 1.26, Gin, GORM y PostgreSQL. Incluye migraciones automáticas, dashboard admin (`/admin`) y documentación (`/swagger/index.html`).
- **Kiosko:** Flutter (Android). Flujo de 3 pasos con OCR on-device (MLKit) para escaneo de INE y validación facial. Todo corre localmente sin APIs de IA externas. Se activa con un código corto que el admin aprueba desde el dashboard (RFC 8628).
- **Residente:** Flutter (Android). Auto-registro con el código de la instalación, login con PIN y generación de invitaciones QR.

## ⚙️ Configuración del Entorno Local
1. Backend
Requiere **Go 1.21+** y **PostgreSQL**.
```bash
cd backend
cp .env.example .env
go run cmd/server/main.go 
```
Asegúrate de configurar tus credenciales de BD y `JWT_SECRET` en el archivo `.env`. El servidor inicia en `http://localhost:8000` con migraciones automáticas.
2. Kiosko

Requiere Flutter 3.x y un dispositivo Android conectado (USB/Depuración).
```Bash
# Redirección de puertos para pruebas locales en dispositivo físico:
adb reverse tcp:8000 tcp:8000

cd kiosko
flutter pub get
flutter run
```
Nota: La URL del backend se configura en `lib/features/registro/services/kiosko_servicio.dart`.
3. Residente
```Bash
cd residente
flutter pub get
flutter run
```
Nota: La URL del backend se configura en `lib/utils/constants.dart`.

## 📡 Documentación API (Swagger)

Con el backend activo, accede a la documentación interactiva en:
👉 `http://localhost:8000/swagger/index.html`

Endpoints Críticos:

|Método | Ruta | Descripción|
| :--- | :--- | :--- |
|POST	|`/api/v1/auth/login`	|Autenticación de administrador (JWT)
|POST	|`/api/v1/auth/device/authorize`	|El kiosko pide un código de activación (RFC 8628)
|POST	|`/api/v1/auth/device/token`	|El kiosko canjea el código por su sesión
|POST	|`/api/v1/auth/kiosko/login`	|Re-autenticación del kiosko (Token de sesión)
|POST	|`/api/v1/kioskos/`	|Crear punto de entrada
|POST	|`/api/v1/kioskos/:id/visitas/`	|Registrar visita (Kiosko)
|GET	|`/api/v1/centros/:codigo/destinos`	|Destinos de una instalación (público)
|POST	|`/api/v1/centros/:codigo/residentes/auto-registro`	|Alta de residente (público, queda pendiente)

Para regenerar la documentación tras modificar handlers:
```Bash
cd backend
go tool swag init -g cmd/server/main.go --parseInternal -o docs
```
## 🧠 Decisiones Técnicas
Las justificaciones de arquitectura (ADRs) están documentadas en:
- [`/backend/docs/adr/`](backend/docs/adr/adr_README.md) — Decisiones del servidor: stack, autenticación por interfaz, multi-tenant, activación de kioskos.
- [`/docs/adr/`](docs/adr/README.md) — Decisiones que cruzan subproyectos, como el sistema de diseño unificado.
- [`/kiosko/docs/`](kiosko/docs/) — Notas de implementación de la app del kiosko.

## 👥 Equipo (Zero Devs)
Facultad de Ciencias de la Computación, BUAP.
- Jose de Jesus Mendoza Reyes
- Jose Alberto Luna Santos
- Diego Alexis Lopez Perez
- Ivan Ramses Ramirez Perez
- Leonardo Lagos Lopez