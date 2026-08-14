DROP INDEX IF EXISTS idx_visitas_placa;

ALTER TABLE visitas DROP CONSTRAINT IF EXISTS visitantes_tipo_documento_check;
ALTER TABLE visitas ADD CONSTRAINT visitantes_tipo_documento_check
  CHECK (tipo_documento = ANY (ARRAY['INE','PASAPORTE','LICENCIA','QR','PIN','ROSTRO']));
