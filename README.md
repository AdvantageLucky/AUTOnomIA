# 🚗 AUTOnomIA

Kiosko de auto-registro de visitantes para fraccionamientos privados. Desarrollado para el **Reto de Industria FEPRO 2026 — BUAP y Kigo**.

## 📌 El Sistema en Breve
- El **visitante se registra** de forma autónoma en la tablet de la caseta.
- El **residente aprueba** o rechaza el acceso desde su teléfono mediante notificaciones push. 
- El **vigilante supervisa** el proceso desde un dashboard web y todo queda en una bitácora auditable.

---
## 🏗️ Arquitectura del Monorepo

```text
autonomia/
├── backend/     API REST en Go — Fuente de verdad del sistema.
├── kiosko/      App Flutter — Terminal para la caseta de vigilancia.
└── residente/   App Flutter — Aplicación móvil para el usuario final.
```
- **Backend:** Go 1.26, Gin, GORM y PostgreSQL. Incluye migraciones automáticas, dashboard admin (`/admin`) y documentación (`/swagger/index.html`).
- **Kiosko:** Flutter (Android). Flujo de 3 pasos con OCR on-device (MLKit) para escaneo de INE y validación facial. Todo corre localmente sin APIs de IA externas.
- **Residente:** Flutter (Android). Login con PIN, generación de invitaciones QR y gestión de solicitudes de acceso.

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
Nota: La URL del backend se configura en `lib/core/services/kiosko_servicio.dart`.
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
|POST	|`/api/v1/auth/acceso/login`	|Autenticación del kiosko (Token de sesión)
|POST	|`/api/v1/accesos/`	|Crear punto de entrada
|POST	|`/api/v1/accesos/:id/visitantes/`	|Registrar visitante (Kiosko)

Para regenerar la documentación tras modificar handlers:
```Bash
cd backend
go tool swag init -g cmd/server/main.go --parseInternal -o docs
```
## 🧠 Decisiones Técnicas
Las justificaciones de arquitectura (ADRs) están documentadas en:
- `/backend/docs/adr/` — Uso de Go, autenticación dual y ClaveKiosko.
- `/kiosko/docs/ADR/` — Patrón MVVM, MLKit local y corrección OCR de CURP.

## 👥 Equipo (Zero Devs)
Facultad de Ciencias de la Computación, BUAP.
- Jose de Jesus Mendoza Reyes
- Jose Alberto Luna Santos
- Diego Alexis Lopez Perez
- Ivan Ramses Ramirez Perez
- Leonardo Lagos Lopez