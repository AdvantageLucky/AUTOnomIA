# Architecture Decision Records (ADR)

Registro de decisiones arquitectónicas significativas del backend de AUTOnomIA, en formato [Nygard](https://github.com/joelparkerhenderson/architecture-decision-record).

Cada ADR es inmutable una vez aceptado: si una decisión cambia, se crea un ADR nuevo que la reemplaza y se marca el anterior como `Superseded by NNNN`.

## Índice
- [0001 - Stack tecnológico base](0001-stack-tecnologico.md)
- [0002 - Documentación de API con OpenAPI/swaggo](0002-openapi-swaggo.md)
- [0003 - Organización por dominio (4 archivos)](0003-organizacion-por-dominio.md)

## Plantilla
```markdown
# NNNN - Título corto

## Status
Accepted | Proposed | Superseded by NNNN

## Context
¿Qué problema o fuerza nos obliga a decidir algo?

## Decision
¿Qué decidimos hacer?

## Consequences
¿Qué se vuelve más fácil o más difícil con esta decisión?
```
