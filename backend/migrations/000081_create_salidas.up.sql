-- Bitacora minima del kiosko de salida: un tap + una foto de rostro, sin
-- resolucion de identidad (no hay INE ni QR en ese flujo, nada contra que
-- cruzar). Ver domain/salidas.
CREATE TABLE salidas (
    id BIGSERIAL PRIMARY KEY,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    deleted_at TIMESTAMPTZ,
    tenant_id BIGINT NOT NULL,
    kiosko_id BIGINT NOT NULL,
    foto_url TEXT NOT NULL DEFAULT ''
);

CREATE INDEX idx_salidas_tenant_id ON salidas (tenant_id);
CREATE INDEX idx_salidas_kiosko_id ON salidas (kiosko_id);
CREATE INDEX idx_salidas_deleted_at ON salidas (deleted_at);
