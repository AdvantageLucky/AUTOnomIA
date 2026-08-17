DROP INDEX IF EXISTS idx_invitaciones_persona_creadora_id;
DROP INDEX IF EXISTS idx_invitaciones_persona_invitada_id;

ALTER TABLE invitaciones DROP COLUMN IF EXISTS permite_reconocimiento_facial;
ALTER TABLE invitaciones DROP COLUMN IF EXISTS persona_creadora_id;
ALTER TABLE invitaciones DROP COLUMN IF EXISTS persona_invitada_id;
