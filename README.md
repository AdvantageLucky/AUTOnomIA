# AUTOnomIA

Kiosko de auto-registro de visitantes para fraccionamientos privados. Reto de industria FEPRO 2026 — BUAP y Kigo.

El visitante llega en su vehículo, se registra solo en la tablet de la caseta, el residente recibe una notificación y aprueba o rechaza desde su teléfono. El vigilante supervisa en el dashboard web. Todo queda en bitácora.

---

## Qué hay en el repo

```
autonomia/
├── backend/     API REST en Go — la fuente de verdad del sistema
├── kiosko/      App Flutter para la tablet de la caseta
└── residente/   App Flutter para el teléfono del residente
```

**Backend** — Go 1.26, Gin, GORM, PostgreSQL. Corre migraciones automáticamente al iniciar. Sirve también el dashboard web de admin en `/admin` y la documentación de la API en `/swagger/index.html`.

**Kiosko** — Flutter/Dart, Android. Flujo de 3 pasos: escanea la INE con OCR on-device (MLKit), toma foto del visitante con validación de rostro, confirma y envía al backend. Sin conexión a APIs externas de IA — todo corre en el dispositivo.

**Residente** — Flutter/Dart, Android. Login con PIN, genera invitaciones QR, ve el historial de visitas, aprueba o rechaza solicitudes de acceso.

---

## Setup manual
### Backend

Se Necesita Go 1.21+ y PostgreSQL corriendo.

```bash
cd backend
cp .env.example .env
# edita .env con tus credenciales de base de datos
go run cmd/server/main.go
```

Las migraciones se aplican solas. El servidor queda en `http://localhost:8000`.

Variables requeridas en `.env`:

```
DB_HOST=127.0.0.1
DB_PORT=5432
DB_USER=
DB_PASSWORD=
DB_NAME=
SERVER_PORT=8000
JWT_SECRET=        # cualquier string para desarrollo local
```

### Kiosko

Necesitas Flutter 3.x y un dispositivo Android conectado por USB con depuración habilitada.

```bash
# si vas a apuntar al backend en tu máquina desde el teléfono
adb reverse tcp:8000 tcp:8000

cd kiosko
flutter pub get
flutter run
```

La URL del backend está hardcodeada en `lib/core/services/kiosko_servicio.dart` — cámbiala si corres el backend en otro lado.

### Residente

```bash
cd residente
flutter pub get
flutter run
```

La URL del backend está en `lib/utils/constants.dart`. Por ahora usa datos locales (SharedPreferences) mientras no está conectada al backend real.

---

## API

Con el backend corriendo, la documentación completa está en:

```
http://localhost:8000/swagger/index.html
```

Endpoints principales:

| Método | Ruta | Qué hace |
|--------|------|----------|
| POST | `/api/v1/auth/login` | Login de admin → JWT |
| POST | `/api/v1/auth/acceso/login` | Login del kiosko → token de sesión |
| POST | `/api/v1/accesos/` | Crear un acceso (punto de entrada) |
| POST | `/api/v1/accesos/:id/visitantes/` | Registrar visitante desde el kiosko |
| GET | `/api/v1/visitantes/` | Listar todos los visitantes (admin) |

El kiosko autentica con token de sesión (opaco, revocable). El admin web y la app residente usan JWT.

---

## Regenerar la documentación de la API

Si modificas un handler, regenera el spec de Swagger:

```bash
cd backend
go tool swag init -g cmd/server/main.go --parseInternal -o docs
```

---

## Decisiones técnicas

Las decisiones no obvias están documentadas como ADRs:
- `backend/docs/adr/` — por qué Go, por qué autenticación dual, cómo se genera la ClaveKiosko
- `kiosko/docs/ADR/` — por qué MVVM con Provider, por qué MLKit en lugar de API externa, cómo funciona la corrección OCR de la CURP

---

## Equipo
Zero Devs — BUAP, Facultad de Ciencias de la Computación.
Jose de Jesus Mendoza Reyes · Jose Alberto Luna Santos · Diego Alexis Lopez Perez · Ivan Ramses Ramirez Perez · Leonardo Lagos Lopez
