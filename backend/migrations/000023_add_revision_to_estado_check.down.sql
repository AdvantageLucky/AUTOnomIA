ALTER TABLE visitas DROP CONSTRAINT IF EXISTS visitas_estado_check;
ALTER TABLE visitas ADD CONSTRAINT visitas_estado_check
  CHECK (estado = ANY (ARRAY['PENDIENTE','APROBADO','RECHAZADO']));
