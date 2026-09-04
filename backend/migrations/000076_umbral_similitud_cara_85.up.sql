-- El umbral de similitud facial para reconocer residentes (login por rostro
-- y BuscarPersonaPorIdentidad) estaba en 0.70, mucho mas laxo que el umbral
-- de 85% que ya se usaba para correlacionar historial de un mismo visitante
-- recurrente (umbral_facial_pct). Dos barras distintas para la misma clase
-- de comparacion (similitud de rostro) producia el peor caso posible: la
-- decision de MAS consecuencia (auto-pasar como si fuera residente) exigia
-- MENOS similitud que la de menos consecuencia (contar como "recurrente"
-- para el score). Se alinean ambas a 85%.
ALTER TABLE kiosko_configs ALTER COLUMN umbral_similitud_cara SET DEFAULT 0.85;

-- Solo se actualizan las filas que siguen en el default viejo (0.70) -- un
-- admin que ya lo haya subido/bajado a mano conserva su valor.
UPDATE kiosko_configs SET umbral_similitud_cara = 0.85 WHERE umbral_similitud_cara = 0.70;
