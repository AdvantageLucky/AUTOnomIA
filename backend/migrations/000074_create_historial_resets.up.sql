-- nombre de tabla "historial_resets": convencion de gorm para el struct
-- visitas.HistorialReset. Marca que la confianza acumulada con una
-- identidad (persona_id) se "olvida" a partir de cierto punto -- sin esto,
-- el historial de visitas usado para calcular el score de confianza
-- (recurrencia, racha limpia, cambio de modalidad) era permanente e
-- irreversible: ni un residente ni un admin tenian forma de decirle al
-- sistema "ya no confio en esta persona como antes".
CREATE TABLE historial_resets (
    id                     BIGSERIAL PRIMARY KEY,
    created_at             TIMESTAMPTZ,
    updated_at             TIMESTAMPTZ,
    deleted_at             TIMESTAMPTZ,
    tenant_id              BIGINT NOT NULL,
    persona_id             BIGINT NOT NULL,
    -- '' = reset global (solo un admin puede hacerlo, aplica en cualquier
    -- destino del tenant); no vacio = un residente reseteo la confianza
    -- solo para SU propia casa, sin afectar como se ve esa identidad en
    -- cualquier otro destino del mismo tenant.
    casa_destino           TEXT NOT NULL DEFAULT '',
    reset_at               TIMESTAMPTZ NOT NULL,
    reset_por_persona_id   BIGINT,
    reset_por_admin_id     BIGINT
);

CREATE INDEX idx_historial_resets_deleted_at ON historial_resets (deleted_at);
CREATE INDEX idx_historial_resets_tenant_persona ON historial_resets (tenant_id, persona_id);
