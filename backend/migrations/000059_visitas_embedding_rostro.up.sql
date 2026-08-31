-- Un flujo de solo rostro + destino no capturaba ningun identificador: sin
-- CURP y sin placa, HistorialDeVisitante no tenia con que agrupar y todas las
-- entradas de una misma persona salian como "primera visita". El autopase no
-- se disparaba nunca ahi, por mucho que la persona viniera a diario.
--
-- Guardar la huella facial de la visita convierte al rostro en identificador:
-- una entrada nueva se compara contra las anteriores del mismo tenant y las
-- que superan el umbral facial son el historial de esa persona.
--
-- Es un vector, no la foto. La foto ya se guardaba antes en foto_rostro_url;
-- esto son 192 flotantes de los que no se puede reconstruir la cara.
ALTER TABLE visitas ADD COLUMN embedding_rostro FLOAT[];

-- Parcial: la mayoria de las filas historicas no tienen embedding y la
-- busqueda 1:N solo mira las que si. No es un indice de similitud (Postgres
-- plano no los tiene sin pgvector), solo acota el scan.
CREATE INDEX idx_visitas_con_embedding
    ON visitas (tenant_id, created_at DESC)
    WHERE embedding_rostro IS NOT NULL;
