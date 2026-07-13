# 0001 - Stack tecnológico base

## Status
Accepted

## Context
El backend de AUTOnomIA necesita servir una API HTTP para registro y control de accesos/visitantes en condominios, persistir datos en una base relacional, y versionar el esquema de esa base de forma reproducible entre entornos.

## Decision
Usar Go como lenguaje, con:
- **Gin** como framework HTTP (router, binding de JSON, middlewares).
- **GORM** como ORM/query builder en runtime (no se usa su auto-migración).
- **golang-migrate** para aplicar migraciones de esquema (carpeta `migrations/`) antes de abrir la conexión GORM, manteniendo el control de esquema separado del ORM.
- **PostgreSQL** como motor de base de datos.

## Consequences
- El flujo de arranque queda fijo: `configs.Load()` → `database.RunMigrations()` → `database.Connect()` → `router.Setup()` (ver `cmd/server/main.go`).
- Cualquier cambio de esquema requiere escribir una migración explícita en `migrations/`; GORM nunca crea ni altera tablas por sí mismo.
- Gin impone el patrón de handlers `func(c *gin.Context)`, lo que a su vez condiciona cómo se documentan los endpoints (ver [0002](0002-openapi-swaggo.md)).
