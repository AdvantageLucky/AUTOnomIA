-- El tiempo de espera pasa de minutos a segundos: ahora controla cuándo el kiosko
-- se libera para el siguiente visitante si la solicitud no se ha resuelto.
ALTER TABLE kiosko_configs RENAME COLUMN tiempo_espera_min TO tiempo_espera_seg;
UPDATE kiosko_configs SET tiempo_espera_seg = tiempo_espera_seg * 60;
ALTER TABLE kiosko_configs ALTER COLUMN tiempo_espera_seg SET DEFAULT 60;
