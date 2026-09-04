-- nombre de tabla "eventos_seguridad": convencion de gorm para el struct
-- seguridad.EventoSeguridad. Antes un intento fallido de PIN o QR en el
-- kiosko no dejaba ningun rastro -- ni notificaba al admin ni guardaba
-- evidencia (foto) de quien lo intento.
CREATE TABLE eventos_seguridad (
    id         BIGSERIAL PRIMARY KEY,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    deleted_at TIMESTAMPTZ,
    tenant_id  BIGINT NOT NULL,
    kiosko_id  BIGINT NOT NULL,
    -- tipo: pin_incorrecto | qr_invalido (mas los que se agreguen despues)
    tipo       TEXT NOT NULL,
    detalle    TEXT NOT NULL DEFAULT '',
    foto_url   TEXT NOT NULL DEFAULT ''
);

CREATE INDEX idx_eventos_seguridad_deleted_at ON eventos_seguridad (deleted_at);
CREATE INDEX idx_eventos_seguridad_tenant_id ON eventos_seguridad (tenant_id);
CREATE INDEX idx_eventos_seguridad_tipo ON eventos_seguridad (tipo);
