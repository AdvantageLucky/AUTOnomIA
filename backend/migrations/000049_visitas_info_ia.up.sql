ALTER TABLE visitas ADD COLUMN resumen_ia TEXT;
ALTER TABLE visitas ADD COLUMN score_ia JSONB;
ALTER TABLE visitas ADD COLUMN persona_id BIGINT REFERENCES personas(id);
CREATE INDEX idx_visitas_persona_id ON visitas (persona_id) WHERE persona_id IS NOT NULL;
