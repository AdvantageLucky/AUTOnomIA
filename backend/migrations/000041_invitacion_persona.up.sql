ALTER TABLE invitaciones ADD COLUMN persona_invitada_id INTEGER;
ALTER TABLE invitaciones ADD COLUMN persona_creadora_id INTEGER;
ALTER TABLE invitaciones ADD COLUMN permite_reconocimiento_facial BOOLEAN NOT NULL DEFAULT false;

CREATE INDEX idx_invitaciones_persona_invitada_id ON invitaciones(persona_invitada_id);
CREATE INDEX idx_invitaciones_persona_creadora_id ON invitaciones(persona_creadora_id);
