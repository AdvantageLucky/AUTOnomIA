-- Hasta ahora un reset de confianza solo podia anclarse a una Persona real
-- (persona_id) -- un visitante identificado solo por su INE (sin cuenta en
-- kigo-app, sin invitacion) no tenia como resetearse: su historial se
-- agrupa por CURP, no por persona_id. Este campo permite un reset anclado
-- al CURP en vez de a una Persona.
ALTER TABLE historial_resets ADD COLUMN curp TEXT NOT NULL DEFAULT '';

-- persona_id ahora puede ser 0 cuando el reset es por CURP (mutuamente
-- excluyente, validado en la capa de Go, no en la base de datos).
CREATE INDEX idx_historial_resets_curp ON historial_resets (tenant_id, curp) WHERE curp <> '';
