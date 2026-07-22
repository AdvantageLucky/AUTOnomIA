-- Revertir renombrado kiosko -> acceso

ALTER TABLE residentes RENAME COLUMN kiosko_id TO acceso_id;
ALTER TABLE destinos RENAME COLUMN kiosko_id TO acceso_id;
ALTER TABLE visitas RENAME COLUMN kiosko_id TO acceso_id;

ALTER TABLE sesion_kioskos RENAME COLUMN kiosko_id TO acceso_id;
ALTER TABLE sesion_kioskos RENAME TO sesion_accesos;

ALTER TABLE kiosko_configs RENAME COLUMN kiosko_id TO acceso_id;
ALTER TABLE kiosko_configs RENAME TO acceso_configs;
ALTER TABLE kioskos RENAME TO accesos;
