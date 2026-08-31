-- umbral_confianza_visitas mezclaba dos cosas distintas y la migracion 000057
-- se equivoco al reinterpretarlo. Su significado original era el NUMERO DE
-- APROBACIONES CONSECUTIVAS que exigia el autopase (default 5, usado por
-- AnalizarVisita -> esConfiable). La 000057 lo redefinio como porcentaje de
-- similitud facial y movio el default a 85, con lo cual el autopase paso a
-- pedir 85 aprobaciones seguidas y dejo de dispararse nunca.
--
-- Aqui se separan los dos umbrales, cada uno con su nombre y su unidad:
--
--   umbral_facial_pct    similitud coseno minima (0-100) para dar por buena una
--                        cara en el kiosko. Es lo que la 000057 queria decir.
--
--   umbral_autopass_pct  score de confianza minimo (0-100) para aprobar sola
--                        una entrada. Reemplaza al contador: el score ya pondera
--                        la racha junto con la evidencia y las anomalias, asi
--                        que un porcentaje dice mas que "5 seguidas".
ALTER TABLE kiosko_configs ADD COLUMN umbral_facial_pct   INT NOT NULL DEFAULT 85;
ALTER TABLE kiosko_configs ADD COLUMN umbral_autopass_pct INT NOT NULL DEFAULT 80;

-- No se puede recuperar el valor original del contador: la 000057 ya piso
-- todas las filas con 85. Se quedan con los defaults nuevos, que reproducen
-- el comportamiento previsto.
ALTER TABLE kiosko_configs DROP COLUMN umbral_confianza_visitas;
