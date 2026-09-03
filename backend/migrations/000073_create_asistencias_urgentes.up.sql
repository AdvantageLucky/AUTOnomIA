-- nombre de tabla "asistencias_urgentes": convencion de gorm para el
-- struct persona.AsistenciaUrgente. Antes el boton de "llamar al vigilante"
-- del kiosko era 100% efimero (solo SSE + correo, sin dejar rastro) -- si el
-- admin no tenia el dashboard abierto en ese instante exacto, la solicitud
-- desaparecia sin dejar ningun registro consultable despues.
CREATE TABLE asistencias_urgentes (
    id                    BIGSERIAL PRIMARY KEY,
    created_at            TIMESTAMPTZ,
    updated_at            TIMESTAMPTZ,
    deleted_at            TIMESTAMPTZ,
    tenant_id             BIGINT NOT NULL,
    kiosko_id             BIGINT NOT NULL,
    motivo                TEXT NOT NULL DEFAULT '',
    estado                TEXT NOT NULL DEFAULT 'pendiente',
    resuelta_por_admin_id BIGINT,
    resuelta_at           TIMESTAMPTZ
);

CREATE INDEX idx_asistencias_urgentes_deleted_at ON asistencias_urgentes (deleted_at);
CREATE INDEX idx_asistencias_urgentes_tenant_id ON asistencias_urgentes (tenant_id);
CREATE INDEX idx_asistencias_urgentes_kiosko_id ON asistencias_urgentes (kiosko_id);
CREATE INDEX idx_asistencias_urgentes_estado ON asistencias_urgentes (estado);
