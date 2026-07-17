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
    acceso_id        BIGINT NOT NULL REFERENCES accesos (id)
);

CREATE INDEX idx_residentes_deleted_at ON residentes (deleted_at);
CREATE INDEX idx_residentes_acceso_id ON residentes (acceso_id);
