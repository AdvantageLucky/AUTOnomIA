UPDATE kiosko_configs SET tiempo_espera_seg = GREATEST(tiempo_espera_seg / 60, 1);
ALTER TABLE kiosko_configs ALTER COLUMN tiempo_espera_seg SET DEFAULT 5;
ALTER TABLE kiosko_configs RENAME COLUMN tiempo_espera_seg TO tiempo_espera_min;
