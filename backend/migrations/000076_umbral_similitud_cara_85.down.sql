ALTER TABLE kiosko_configs ALTER COLUMN umbral_similitud_cara SET DEFAULT 0.70;
UPDATE kiosko_configs SET umbral_similitud_cara = 0.70 WHERE umbral_similitud_cara = 0.85;
