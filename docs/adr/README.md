# Architecture Decision Records — nivel de producto

Decisiones arquitectónicas que **cruzan más de un subproyecto** del monorepo (backend, kiosko,
residente), en formato [Nygard](https://github.com/joelparkerhenderson/architecture-decision-record).

Las decisiones que solo afectan al servidor viven en su propio índice:
[`backend/docs/adr/`](../../backend/docs/adr/adr_README.md).

Cada ADR es inmutable una vez aceptado: si una decisión cambia, se crea un ADR nuevo que la
reemplaza y se marca el anterior como `Superseded by NNNN`.

## Índice de Decisiones
- [0001 - Sistema de diseño unificado entre los tres productos](0001-sistema-diseno-unificado.md)

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
