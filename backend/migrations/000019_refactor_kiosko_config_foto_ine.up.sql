ALTER TABLE kiosko_configs DROP COLUMN foto_ine_visitante;
ALTER TABLE kiosko_configs DROP COLUMN foto_ine_invitado;
ALTER TABLE kiosko_configs ADD COLUMN ine_obligatorio_invitado BOOLEAN NOT NULL DEFAULT false;
