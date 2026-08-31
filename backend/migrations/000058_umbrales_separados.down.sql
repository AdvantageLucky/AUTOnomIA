ALTER TABLE kiosko_configs ADD COLUMN umbral_confianza_visitas INT NOT NULL DEFAULT 5;

ALTER TABLE kiosko_configs DROP COLUMN umbral_autopass_pct;
ALTER TABLE kiosko_configs DROP COLUMN umbral_facial_pct;
