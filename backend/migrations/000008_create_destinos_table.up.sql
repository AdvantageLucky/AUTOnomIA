CREATE TABLE destinos (
    id         BIGSERIAL PRIMARY KEY,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    deleted_at TIMESTAMPTZ,
    nombre     TEXT NOT NULL,
    titular    TEXT NOT NULL,
    acceso_id  BIGINT NOT NULL REFERENCES accesos (id)
);

CREATE INDEX idx_destinos_deleted_at ON destinos (deleted_at);
CREATE INDEX idx_destinos_acceso_id ON destinos (acceso_id);
