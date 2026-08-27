ALTER TABLE kiosko_configs ADD COLUMN foto_ine_visitante BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE kiosko_configs ADD COLUMN pasos_sin_invitacion TEXT NOT NULL DEFAULT '["ROSTRO","DESTINO"]';
