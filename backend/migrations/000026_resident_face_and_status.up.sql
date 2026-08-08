ALTER TABLE centros_habitacionales ADD COLUMN codigo TEXT UNIQUE;

ALTER TABLE residentes ADD COLUMN status TEXT NOT NULL DEFAULT 'activo';
ALTER TABLE residentes ADD COLUMN foto_cara_url TEXT;
ALTER TABLE residentes ADD COLUMN embedding FLOAT[];
ALTER TABLE residentes ALTER COLUMN kiosko_id DROP NOT NULL;

ALTER TABLE kiosko_configs ADD COLUMN umbral_similitud_cara FLOAT NOT NULL DEFAULT 0.70;
