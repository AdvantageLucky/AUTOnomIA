CREATE TABLE personas (
    id                      BIGSERIAL PRIMARY KEY,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at              TIMESTAMPTZ,
    telefono                TEXT NOT NULL,
    telefono_verificado_at  TIMESTAMPTZ,
    nombre                  TEXT NOT NULL DEFAULT '',
    apellido_paterno        TEXT NOT NULL DEFAULT '',
    apellido_materno        TEXT NOT NULL DEFAULT '',
    embedding               FLOAT[],
    foto_cara_url           TEXT NOT NULL DEFAULT '',
    qr_secreto              TEXT NOT NULL
);

CREATE UNIQUE INDEX idx_personas_telefono ON personas (telefono) WHERE deleted_at IS NULL;
CREATE INDEX idx_personas_deleted_at ON personas (deleted_at);

CREATE TABLE membresias (
    id                              BIGSERIAL PRIMARY KEY,
    created_at                      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at                      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at                      TIMESTAMPTZ,
    persona_id                      BIGINT NOT NULL REFERENCES personas(id),
    tenant_id                       BIGINT NOT NULL REFERENCES centros_habitacionales(id),
    casa_destino                    TEXT NOT NULL,
    pin                             TEXT NOT NULL,
    rol                             TEXT NOT NULL DEFAULT 'titular',
    status                          TEXT NOT NULL DEFAULT 'activo',
    permite_reconocimiento_facial   BOOLEAN NOT NULL DEFAULT false,
    kiosko_id                       BIGINT,
    tiempo_espera_min               INT
);

CREATE INDEX idx_membresias_persona_id ON membresias (persona_id);
CREATE INDEX idx_membresias_tenant_id ON membresias (tenant_id);
CREATE INDEX idx_membresias_deleted_at ON membresias (deleted_at);
