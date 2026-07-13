# 0003 - Organización por dominio (4 archivos)

## Status
Accepted

## Context
La aplicación maneja varios recursos de negocio (accesos, visitantes, usuarios, kioskos) que son multi-tenant: cada recurso pertenece a un admin y un admin solo debe poder ver/modificar sus propios recursos. Se necesita un patrón repetible para añadir dominios nuevos sin reinventar la estructura cada vez.

## Decision
Cada dominio de negocio vive en su propio paquete bajo `internal/domain/<nombre>/`, con 4 archivos de responsabilidad fija:
- `model.go` — struct GORM (embebe `gorm.Model`) que representa la tabla.
- `dtos.go` — structs `*Request`/`*Response` para bindear entrada y dar forma a la salida; el model nunca se expone directamente en las respuestas.
- `repository.go` — `Repository{db *gorm.DB}` con métodos CRUD construidos vía `NewRepository(db)`; las queries multi-tenant filtran siempre por `adminID` (`FindAllByAdminID`, `FindByIDAndAdminID`, etc.).
- `handlers.go` — `Handler{repo *Repository}` con un método `gin.HandlerFunc` por endpoint, construido vía `NewHandler(repo)`.

El repo y el handler de cada dominio se instancian en `internal/router/router.go` (función `register<Dominio>Routes`), no dentro del propio paquete de dominio.

## Consequences
- Añadir un dominio nuevo es mecánico: replicar los 4 archivos siguiendo `internal/domain/acceso/` como referencia.
- El filtrado por `adminID` en el repository es la única barrera de aislamiento multi-tenant; mientras no exista `internal/domain/auth/` implementado, ese `adminID` queda hardcodeado a `1` en los handlers (ver TODOs en `acceso/handlers.go`), lo que es aceptable solo mientras no haya autenticación real.
- Instanciar repo/handler en el router (no en el dominio) mantiene los paquetes de dominio libres de lógica de wiring, a costa de que `router.go` crece con una función por dominio.
