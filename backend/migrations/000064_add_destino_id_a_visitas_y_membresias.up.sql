ALTER TABLE visitas ADD COLUMN destino_id BIGINT REFERENCES destinos (id);
ALTER TABLE membresias ADD COLUMN destino_id BIGINT REFERENCES destinos (id);

CREATE INDEX idx_visitas_destino_id ON visitas (destino_id);
CREATE INDEX idx_membresias_destino_id ON membresias (destino_id);

-- Backfill: liga registros existentes a su destino por coincidencia de
-- texto (mismo idioma de match que ya usa FindCompanerosCasa). Ambas
-- columnas quedan NULL para filas sin match -- la UI debe tolerar null y
-- caer al texto (casa_destino) como hoy.
UPDATE visitas v
SET destino_id = d.id
FROM destinos d
WHERE d.tenant_id = v.tenant_id
  AND UPPER(TRIM(d.nombre)) = UPPER(TRIM(v.casa_destino))
  AND v.deleted_at IS NULL;

UPDATE membresias m
SET destino_id = d.id
FROM destinos d
WHERE d.tenant_id = m.tenant_id
  AND UPPER(TRIM(d.nombre)) = UPPER(TRIM(m.casa_destino))
  AND m.deleted_at IS NULL;
