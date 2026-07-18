ALTER TABLE visitas DROP COLUMN estado;
ALTER TABLE visitas DROP COLUMN placa;
ALTER TABLE visitas DROP COLUMN casa_destino;
ALTER TABLE visitas DROP COLUMN motivo_visita;

ALTER INDEX idx_visitas_curp RENAME TO idx_visitantes_curp;
ALTER INDEX idx_visitas_acceso_id RENAME TO idx_visitantes_acceso_id;
ALTER INDEX idx_visitas_deleted_at RENAME TO idx_visitantes_deleted_at;
ALTER TABLE visitas RENAME TO visitantes;
