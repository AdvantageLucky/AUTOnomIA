CREATE TABLE residentes (
    id               BIGSERIAL PRIMARY KEY,
    created_at       TIMESTAMPTZ,
    updated_at       TIMESTAMPTZ,
    deleted_at       TIMESTAMPTZ,
    nombre           TEXT NOT NULL,
    apellido_paterno TEXT NOT NULL,
    apellido_materno TEXT NOT NULL,
    pin              TEXT NOT NULL,
    casa_destino     TEXT NOT NULL,
    telefono         TEXT NOT NULL DEFAULT '',
    kiosko_id        BIGINT,
    tiempo_espera_min INTEGER,
    tenant_id        BIGINT NOT NULL REFERENCES centros_habitacionales(id),
    status           TEXT NOT NULL DEFAULT 'activo',
    foto_cara_url    TEXT,
    embedding        FLOAT[],
    device_token     TEXT
);
CREATE INDEX idx_residentes_deleted_at ON residentes (deleted_at);
CREATE INDEX idx_residentes_tenant_id ON residentes (tenant_id);
