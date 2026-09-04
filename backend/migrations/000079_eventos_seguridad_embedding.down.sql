DROP INDEX IF EXISTS idx_eventos_seguridad_con_embedding;
ALTER TABLE eventos_seguridad DROP COLUMN embedding_rostro;
ALTER TABLE eventos_seguridad DROP COLUMN intentos_previos;
