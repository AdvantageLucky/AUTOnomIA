# ADR-0012: Búsqueda fuzzy multi-campo en bitácora de visitas

**Estado:** Aceptado  
**Fecha:** 2026-07-17

## Contexto

El OCR sobre la INE es inconsistente por naturaleza: nombres pueden tener letras transpuestas, la CURP puede tener confusiones O/0 e I/1. Buscar por CURP exacta en la UI es frágil y fuerza al operador a saber la CURP de memoria. Se necesita una búsqueda que funcione con cualquier fragmento de texto: un nombre parcial, los primeros dígitos de la CURP, una placa, o el nombre del destino.

## Decisión

### Normalización en escritura

Al guardar una `Visita`, el service layer aplica `strings.ToUpper(strings.TrimSpace(...))` sobre los campos de origen OCR: `Nombre`, `CURP`, `ClaveElector`, `CasaDestino`, `Placa`. Esto garantiza consistencia en la DB sin necesidad de migración sobre datos existentes (los datos viejos se normalizan la primera vez que se actualicen).

### Endpoint modificado

`GET /api/v1/visitas/` acepta un query param `q` adicional a los filtros existentes (`estado`, `tipo_documento`, paginación). Cuando `q` está presente:

```sql
WHERE (
    nombre        ILIKE '%q%' OR
    curp          ILIKE '%q%' OR
    clave_elector ILIKE '%q%' OR
    casa_destino  ILIKE '%q%' OR
    placa         ILIKE '%q%'
)
```

Se aplica sobre el `q` en uppercase para que coincida con los datos normalizados.

### Eliminación del endpoint `/visitas/buscar`

El endpoint `GET /api/v1/visitas/buscar?curp=` queda obsoleto. Se elimina en favor del param `q` en el endpoint principal. La UI unifica la búsqueda en la pantalla de Visitas.

### UI

- Se elimina la pestaña "Buscar CURP" del dashboard.
- La pantalla Visitas tiene un campo de búsqueda único que envía el texto como `q`.
- El input aplica debounce de 300ms para evitar requests en cada tecla.

## Consecuencias

- `ILIKE` no usa índices en PostgreSQL a menos que se configure `pg_trgm`. Para los volúmenes esperados (miles de visitas por kiosko) es suficiente sin índice trigram. Si escala, se puede añadir `CREATE INDEX ... USING GIN (nombre gin_trgm_ops)` como optimización posterior.
- Los datos históricos (previos a normalización) se devolverán correctamente porque el `ILIKE` es case-insensitive; solo el display en frontend mostrará el casing original hasta que se actualicen.
