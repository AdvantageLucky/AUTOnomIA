ALTER TABLE residentes ADD COLUMN device_token TEXT;

-- 60s alcanzaba para "libera el kiosko si nadie interactúa"; ahora también
-- es cuánto tiempo tiene el residente para responder desde su celular a la
-- notificación de una visita, así que necesita más margen.
ALTER TABLE kiosko_configs ALTER COLUMN tiempo_espera_seg SET DEFAULT 90;
