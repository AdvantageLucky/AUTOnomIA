-- se renombra la tabla y se agregan los campos del nuevo flujo de registro
ALTER TABLE visitantes RENAME TO visitas;
ALTER INDEX idx_visitantes_deleted_at RENAME TO idx_visitas_deleted_at;
ALTER INDEX idx_visitantes_acceso_id RENAME TO idx_visitas_acceso_id;
ALTER INDEX idx_visitantes_curp RENAME TO idx_visitas_curp;

ALTER TABLE visitas ADD COLUMN motivo_visita TEXT NOT NULL DEFAULT '';
ALTER TABLE visitas ADD COLUMN casa_destino TEXT NOT NULL DEFAULT '';
ALTER TABLE visitas ADD COLUMN placa TEXT NOT NULL DEFAULT '';
ALTER TABLE visitas ADD COLUMN estado TEXT NOT NULL DEFAULT 'PENDIENTE'
    CHECK (estado IN ('PENDIENTE', 'APROBADO', 'RECHAZADO'));

ALTER TABLE visitas ALTER COLUMN motivo_visita DROP DEFAULT;
ALTER TABLE visitas ALTER COLUMN casa_destino DROP DEFAULT;
