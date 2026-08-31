-- Solo se revierte el default. Los valores ya migrados se quedan: volver a
-- ponerlos en 5 dejaria el umbral facial en 0.05 si el kiosko sigue leyendo
-- el campo, que es justo lo que esta migracion evita.
ALTER TABLE kiosko_configs ALTER COLUMN umbral_confianza_visitas SET DEFAULT 5;
