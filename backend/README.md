# AUTOnomIA Backend
Backend del proyecto **AUTOnomIA** para la **FEPRO 2026** de la **BUAP**. 
Este sistema gestiona el registro y control de visitantes, configuración de kioskos y panel de administración general.
Desarrollado en **Go** utilizando el framework web **Gin**, **GORM**, **go-migrate**, etc para la persistencia de datos.

## Requisitos Previos
- **Go**: Versión `1.26` o superior.
- **PostgreSQL**: Para almacenamiento de base de datos.

## Configuración e Instalación
1. **Configurar las variables de entorno:**
   Copia el archivo de ejemplo `.env.example` como `.env` y rellena las credenciales correspondientes a tu base de datos y servidor:
   ```bash
   cp .env.example .env
   ```

2. **Instalar dependencias:**
   ```bash
   go mod download
   ```

## Ejecución en Desarrollo
Para iniciar el servidor de desarrollo, ejecuta el siguiente comando desde la raíz del proyecto:
```bash
go run cmd/server/main.go
```
El servidor web iniciará escuchando en el puerto `SERVER_PORT` proveniente de `.env`.

## Estructura del Proyecto
La estructura del código sigue el siguiente patrón de diseño:

- **`cmd/server/`**: Punto de entrada de la aplicación (`main.go`).

- **`internal/`**: Contiene la lógica interna y del negocio del backend:
  - **`config/`**: Carga y validación de variables de entorno de la aplicación.
  - **`db/`**: Conexión a la base de datos y configuración del ORM.
  - **`domain/`**: Módulos y dominios de negocio (ej. `visitante`).
  - **`router/`**: Configuración del enrutador (Gin Gonic) y registro de endpoints.

- **`migrations/`**: Scripts SQL de migración para la estructura de la base de datos.

## Endpoints API ()
### Visitantes (`/api/v1/visitors`)
- `POST /register`: Registrar un nuevo visitante.
- `GET /`: Listar visitantes.
- `GET /:id`: Obtener detalles de un visitante en específico.
- `PATCH /:id/status`: Actualizar el estado de acceso de un visitante.

---
KIGO - FEPRO 2026 - BUAP.
