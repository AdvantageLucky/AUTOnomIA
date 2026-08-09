# 0021 - Aislamiento multi-tenant: un tenant por admin y scopes calificados en JOIN

## Status
Accepted (complementa a [0018](0018-multitenancy-centro-habitacional.md))

## Context
[0018](0018-multitenancy-centro-habitacional.md) introdujo `CentroHabitacional` como entidad raíz y
la migración `000025` añadió la columna de tenant a todas las tablas de dominio. La implementación
en Go quedó incompleta en dos puntos que anulaban el aislamiento que el ADR buscaba:

1. **Todo admin nuevo caía en el mismo tenant.** `RegisterAdminWithMailAndPassword` y
   `RegisterWithGoogle` asignaban `TenantID: 1` fijo — el «tenant cero» que la propia migración
   `000025` siembra para adoptar los datos heredados. En la práctica, cualquier cuenta registrada
   compartía kioskos, residentes, visitas y destinos con todas las demás. El aislamiento existía en
   el esquema pero no en el código que escribe.

2. **El scope de tenant rompía las consultas con JOIN.** `ByTenant` añadía
   `WHERE tenant_id = ?` sin calificar la tabla. En las consultas que hacen JOIN contra otra tabla
   que *también* tiene `tenant_id` (`visitas JOIN kioskos`, `residentes JOIN kioskos`) PostgreSQL
   respondía `SQLSTATE 42702 — column reference "tenant_id" is ambiguous`, dejando caídos el listado
   de visitas y el de residentes por admin.

Un intento previo de resolver (2) leyendo `db.Statement.Table` dentro del scope no funciona: gorm
ejecuta los scopes en `processor.Execute` **antes** de parsear el modelo, así que `Statement.Table`
todavía está vacío cuando el scope corre.

> Nota sobre el esquema: [0018](0018-multitenancy-centro-habitacional.md) nombra la clave foránea
> como `centro_habitacional_id`, pero la migración `000025` la creó como **`tenant_id`**. El nombre
> vigente en la base de datos es `tenant_id`.

## Decision
**Un tenant por admin.** Cada administrador que se registra —por correo o por Google— crea su propio
`CentroHabitacional` vacío y queda como su dueño. Un vigilante dado de alta desde el dashboard no
crea tenant: hereda el del admin que lo crea, leído de las claims del JWT del solicitante.

**Dos scopes explícitos**, y quien escribe la consulta elige:

- `ByTenant` — para consultas sobre una sola tabla. Emite `tenant_id = ?` sin calificar.
- `ByTenantFor(tabla)` — para consultas con JOIN. Emite `tabla.tenant_id = ?`.

`ByTenantFor` recibe el nombre de la tabla como argumento y lo captura en una *closure* en tiempo de
definición, en lugar de intentar deducirlo del statement en tiempo de ejecución.

## Consequences
- El asistente de configuración inicial del dashboard puede usar «tenant sin nombre» como señal
  fiable de instalación recién creada, en vez de inferirlo de si hay kioskos dados de alta.
- Elegir el scope correcto es un **contrato manual**: si alguien añade un JOIN a una consulta que usa
  `ByTenant`, el error de ambigüedad reaparece. El compilador no lo detecta y no hay test que lo
  cubra hoy.
- Los datos creados antes de este cambio siguen colgando del tenant `1`. No hay migración de
  reasignación: las cuentas que ya existían permanecen compartiendo ese tenant hasta separarlas a
  mano.
- `KioskoConfig` no declaraba `TenantID` en el struct de Go aunque la columna existía y era
  `NOT NULL`; crear la configuración por defecto de un kiosko fallaba con `SQLSTATE 23502`. El campo
  se añadió al modelo y se propaga desde el kiosko padre.
- El aislamiento sigue dependiendo de que cada repositorio aplique el scope. No hay Row Level
  Security en PostgreSQL que lo garantice por debajo; una consulta que olvide el scope ve todos los
  tenants.
