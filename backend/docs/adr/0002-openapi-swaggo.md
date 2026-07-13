# 0002 - Documentación de API con OpenAPI/swaggo

## Status
Accepted

## Context
La API crece dominio por dominio (ver [0003](0003-organizacion-por-dominio.md)) y no hay todavía cliente frontend ni contrato formal de endpoints. Se necesita una forma de documentar la API que viva junto al código y no se desincronice fácilmente con los handlers reales.

## Decision
Documentar la API con anotaciones [swaggo/swag](https://github.com/swaggo/swag) directamente sobre cada handler en `internal/domain/<dominio>/handlers.go`, y servir la UI con [gin-swagger](https://github.com/swaggo/gin-swagger) en `/swagger/index.html`.

Detalles de implementación:
- `swag` se instala como *tool dependency* en `go.mod` (`go get -tool ...`), no como binario global, para que la versión quede fijada y reproducible (`go tool swag init ...`).
- El spec se genera con `--parseInternal`, porque todo el código de dominio vive bajo `internal/` y swag no lo escanea por defecto.
- El entrypoint se indica explícitamente con `-g cmd/server/main.go`, ya que `main.go` no está en la raíz del módulo.
- El paquete generado `docs/` se importa en blanco (`_ "kigo-autonomia-backend/docs"`) desde `cmd/server/main.go` para que `gin-swagger` encuentre el spec en runtime.
- swaggo v1 genera **Swagger 2.0**, no OpenAPI 3.x. Se eligió v1 por ser la versión madura y mejor soportada por `gin-swagger`; si en el futuro se requiere OpenAPI 3.x de forma estricta, evaluar `swaggo/swag` v2 (menos maduro al día de esta decisión) en un ADR nuevo.

## Consequences
- El spec (`docs/docs.go`, `docs/swagger.json`, `docs/swagger.yaml`) se **commitea** al repo en vez de ignorarse, porque no hay CI que lo regenere — sin esto, `go build` fallaría para cualquiera sin `swag` instalado.
- Cada vez que se añade o modifica un endpoint, hay que correr manualmente `go tool swag init -g cmd/server/main.go --parseInternal -o docs`; si se olvida, el spec queda desactualizado silenciosamente.
- Las anotaciones quedan acopladas al handler como comentarios; no hay verificación en tiempo de compilación de que coincidan con los DTOs reales.
