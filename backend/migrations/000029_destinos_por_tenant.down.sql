UPDATE destinos SET kiosko_id = 0 WHERE kiosko_id IS NULL;
ALTER TABLE destinos ALTER COLUMN kiosko_id SET NOT NULL;
