ALTER TABLE kiosko_configs DROP COLUMN  ine_obligatorio_invitado; 
ALTER TABLE kiosko_configs ADD COLUMN foto_ine_visitante BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE kiosko_configs ADD COLUMN foto_ine_invitado BOOLEAN NOT NULL DEFAULT false;
