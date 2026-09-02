ALTER TABLE kiosko_configs ADD COLUMN usar_placa_en_score_ia BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE kiosko_configs ADD COLUMN usar_documento_en_score_ia BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE kiosko_configs ADD COLUMN usar_rostro_en_score_ia BOOLEAN NOT NULL DEFAULT true;
