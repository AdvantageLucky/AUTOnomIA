-- Embedding facial (192 flotantes, MobileFaceNet) del rostro capturado en
-- segundo plano durante un intento fallido (PIN incorrecto, QR invalido) --
-- convierte el rostro en identificador para poder correlacionar si la misma
-- persona ya intento antes, igual que Visita.embedding_rostro (ver
-- 000059_visitas_embedding_rostro) para el historial de visitas.
ALTER TABLE eventos_seguridad ADD COLUMN embedding_rostro FLOAT[];

-- Cuantos eventos ANTERIORES de este mismo tenant tienen un rostro que
-- correlaciona con este (ver seguridad.similitudCoseno) -- se calcula una
-- sola vez, al crear el evento (mismo criterio que Visita.PersonaID: barato
-- de leer despues, en vez de recalcular el scan 1:N cada vez que el
-- dashboard hace polling de la lista).
ALTER TABLE eventos_seguridad ADD COLUMN intentos_previos INT NOT NULL DEFAULT 0;

-- Mismo motivo que idx_visitas_con_embedding: acota el scan 1:N en memoria a
-- las filas que si tienen con que comparar (Postgres plano no tiene indice
-- de similitud sin pgvector).
CREATE INDEX idx_eventos_seguridad_con_embedding
    ON eventos_seguridad (tenant_id, created_at DESC)
    WHERE embedding_rostro IS NOT NULL;
