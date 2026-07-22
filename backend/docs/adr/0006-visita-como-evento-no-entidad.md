# 0006 - Visita como evento de kiosko, no como entidad de persona

## Status
Accepted

## Context
El dominio original se llamaba `visitantes/` y el modelo era `Visitante`. El nombre sugiere que el
sistema modela **personas** — pero el sistema en realidad necesita modelar **eventos de kiosko**:
una misma persona puede visitar el condominio múltiples veces y cada registro debe ser
independiente, con su propio motivo, destino, estado de aprobación y timestamp.

`visitantes/` con un modelo `Visitante` invita a tratar cada registro como si representara a la
persona de forma canónica, lo que abriría la puerta a actualizaciones erróneas, deduplicación
prematura, o a asumir que hay un "visitante" que persiste entre visitas — ninguna de esas
semánticas aplica aquí.

También se agregaron campos nuevos (`motivo_visita`, `casa_destino`, `placa`, `estado`) que son
propiedades del evento de kiosko, no de una persona, lo que hacía aún más incorrecto el nombre
original.

## Decision
Renombrar el dominio a `visitas/` y el modelo a `Visita`. La tabla en Postgres se renombra de
`visitantes` a `visitas` mediante la migración `000007`. El endpoint principal pasa de
`/kioskos/:id/visitantes/` a `/kioskos/:id/visitas/`.

El campo `estado` (`PENDIENTE` | `APROBADO` | `RECHAZADO`) se modela como un enum en Go y como
un `CHECK` constraint en Postgres, garantizando que ninguna capa pueda escribir un valor fuera del
conjunto válido.

## Consequences
- Cualquier cliente (kiosko, dashboard, app residente) debe actualizar su URL de registro
  de `/visitantes/` a `/visitas/`.
- La migración `000007` renombra la tabla y los índices asociados antes de agregar las columnas
  nuevas; el `.down.sql` invierte el orden exacto.
- El campo `estado` tiene un default de `PENDIENTE` en base de datos, lo que hace que cualquier
  registro nuevo quede en espera sin que el handler necesite setear el campo explícitamente.
- No hay entidad canónica de persona visitante — si en el futuro se necesita historial agregado
  por CURP, se derivará desde la tabla `visitas` con un query, no desde un modelo separado.
