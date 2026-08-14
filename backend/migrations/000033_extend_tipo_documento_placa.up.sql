-- En un acceso vehicular no se captura documento de identidad: la placa es lo
-- que identifica la visita (ver ADR-0024).
ALTER TABLE visitas DROP CONSTRAINT IF EXISTS visitantes_tipo_documento_check;
ALTER TABLE visitas ADD CONSTRAINT visitantes_tipo_documento_check
  CHECK (tipo_documento = ANY (ARRAY['INE','PASAPORTE','LICENCIA','QR','PIN','ROSTRO','PLACA']));

-- HistorialDeVisitante agrupa por placa cuando no hay curp, y corre en cada
-- registro de un kiosko vehicular; sin indice esa consulta hace seq scan.
CREATE INDEX IF NOT EXISTS idx_visitas_placa ON visitas (placa);
