DROP INDEX IF EXISTS idx_visitas_destino_id;
DROP INDEX IF EXISTS idx_membresias_destino_id;
ALTER TABLE visitas DROP COLUMN destino_id;
ALTER TABLE membresias DROP COLUMN destino_id;
