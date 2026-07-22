ALTER TABLE visitas ADD COLUMN intervenida BOOLEAN NOT NULL DEFAULT false;

ALTER TABLE kiosko_configs ADD COLUMN auto_pass_habilitado BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE kiosko_configs ADD COLUMN umbral_confianza_visitas INT NOT NULL DEFAULT 5;
