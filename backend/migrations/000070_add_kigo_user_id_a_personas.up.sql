ALTER TABLE personas ADD COLUMN kigo_user_id TEXT;

CREATE UNIQUE INDEX idx_personas_kigo_user_id ON personas (kigo_user_id) WHERE kigo_user_id IS NOT NULL;
