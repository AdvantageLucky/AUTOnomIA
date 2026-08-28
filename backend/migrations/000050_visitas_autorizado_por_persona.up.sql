-- Quien resolvio la visita, no solo con que rol. Sin esto el historial de la
-- app solo puede acotarse a "aprobada por algun residente de la casa", y a un
-- residente le aparecian las que resolvieron los demas miembros del domicilio.
ALTER TABLE visitas ADD COLUMN autorizado_por_persona_id BIGINT REFERENCES personas(id);

CREATE INDEX idx_visitas_autorizado_por_persona
    ON visitas (autorizado_por_persona_id)
    WHERE autorizado_por_persona_id IS NOT NULL;
