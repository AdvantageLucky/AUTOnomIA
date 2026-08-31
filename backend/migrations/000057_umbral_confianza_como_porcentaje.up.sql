-- umbral_confianza_visitas nacio con default 5 y nunca lo leyo nadie: el
-- dashboard no lo mandaba en el PATCH y el kiosko comparaba contra un 0.85
-- clavado en coincidencia_facial_local.dart. Al conectarlo de punta a punta
-- hay que fijar su unidad, porque un 5 interpretado como porcentaje da un
-- umbral de 0.05 y hace match con cualquier cara.
--
-- Queda definido como PORCENTAJE de similitud coseno (0-100); el kiosko lo
-- divide entre 100. 85 conserva exactamente el comportamiento que ya tenia.
--
-- El UPDATE puede tocar todas las filas sin miedo: como el admin nunca pudo
-- escribir este campo, cualquier valor por debajo de 50 es el default viejo,
-- no una decision de alguien.
ALTER TABLE kiosko_configs ALTER COLUMN umbral_confianza_visitas SET DEFAULT 85;

UPDATE kiosko_configs SET umbral_confianza_visitas = 85 WHERE umbral_confianza_visitas < 50;
