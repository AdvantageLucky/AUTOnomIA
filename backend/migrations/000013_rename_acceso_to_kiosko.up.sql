-- Renombrar tablas y columnas: acceso -> kiosko

ALTER TABLE accesos RENAME TO kioskos;
ALTER TABLE acceso_configs RENAME TO kiosko_configs;
ALTER TABLE kiosko_configs RENAME COLUMN acceso_id TO kiosko_id;

ALTER TABLE sesion_accesos RENAME TO sesion_kioskos;
ALTER TABLE sesion_kioskos RENAME COLUMN acceso_id TO kiosko_id;

ALTER TABLE visitas RENAME COLUMN acceso_id TO kiosko_id;
ALTER TABLE destinos RENAME COLUMN acceso_id TO kiosko_id;
ALTER TABLE residentes RENAME COLUMN acceso_id TO kiosko_id;
