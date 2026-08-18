ALTER TABLE kiosko_configs ALTER COLUMN tiempo_espera_seg SET DEFAULT 60;
ALTER TABLE residentes DROP COLUMN IF EXISTS device_token;
