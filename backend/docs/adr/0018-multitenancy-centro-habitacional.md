s# 0016 - Arquitectura Multi-tenant con CentroHabitacional

## Status
Proposed

## Context
Actualmente, la base de datos de AUTOnomIA opera en un modelo de inquilino único (Single-tenant). Las migraciones actuales han creado un esquema plano donde todos los registros de `admins`, `kioskos`, `residentes`, `destinos`, `visitantes` y `visitas` comparten el mismo espacio de datos global. Para escalar la plataforma como SaaS y ofrecerla a múltiples complejos residenciales simultáneamente, es imperativo aislar los datos para garantizar que las operaciones de un complejo no expongan la información de otro.

## Decision
Implementar una arquitectura multi-tenant a nivel de esquema de base de datos introduciendo la entidad raíz `centros_habitacionales`.

Se creará una nueva tabla y se añadirá una clave foránea (Foreign Key) `centro_habitacional_id` a las siguientes tablas de dominio para garantizar el aislamiento horizontal:
* `admins`
* `kioskos`
* `residentes`
* `destinos`
* `visitas`

Para evitar la pérdida de los datos de prueba existentes y mantener la integridad referencial, la migración ejecutará las siguientes fases en orden:
1. **Fase de Creación:** Crear la tabla `centros_habitacionales`.
2. **Fase de Semilla (Seed):** Insertar un registro genérico/por defecto.
3. **Fase de Alteración:** Añadir la columna `centro_habitacional_id` permitiendo nulos, actualizar los registros asignándoles el ID por defecto, modificar la columna a `NOT NULL` y establecer las restricciones de clave foránea.

## Consequences
* El aislamiento lógico de los datos de los clientes sienta las bases para implementar resúmenes y estadísticas globales por centro habitacional.
* La refactorización del código Go requerirá que la totalidad de las consultas en los repositorios sean actualizadas para incluir el filtro del tenant.
* Toda llamada a la API requerirá inyectar y validar el Tenant ID desde el middleware de autenticación hacia el contexto de la petición.