ALTER TABLE kiosko_configs DROP COLUMN IF EXISTS umbral_similitud_cara;

ALTER TABLE residentes ALTER COLUMN kiosko_id SET NOT NULL;
ALTER TABLE residentes DROP COLUMN IF EXISTS embedding;
ALTER TABLE residentes DROP COLUMN IF EXISTS foto_cara_url;
ALTER TABLE residentes DROP COLUMN IF EXISTS status;

ALTER TABLE centros_habitacionales DROP COLUMN IF EXISTS codigo;
