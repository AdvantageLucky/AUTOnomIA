DROP INDEX idx_visitas_persona_id;
ALTER TABLE visitas DROP COLUMN resumen_ia;
ALTER TABLE visitas DROP COLUMN score_ia;
ALTER TABLE visitas DROP COLUMN persona_id;
