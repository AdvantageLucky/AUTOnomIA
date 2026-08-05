ALTER TABLE visitas DROP CONSTRAINT visitas_estado_check;
ALTER TABLE visitas ADD CONSTRAINT visitas_estado_check
    CHECK (estado IN ('PENDIENTE', 'APROBADO', 'RECHAZADO'));
