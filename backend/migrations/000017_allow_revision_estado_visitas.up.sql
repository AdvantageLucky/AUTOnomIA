-- La restriccion original (000007) no incluia REVISION, pero el analisis de
-- anomalias y el timeout de espera del anfitrion sí lo escriben en estado.
ALTER TABLE visitas DROP CONSTRAINT visitas_estado_check;
ALTER TABLE visitas ADD CONSTRAINT visitas_estado_check
    CHECK (estado IN ('PENDIENTE', 'APROBADO', 'RECHAZADO', 'REVISION'));
