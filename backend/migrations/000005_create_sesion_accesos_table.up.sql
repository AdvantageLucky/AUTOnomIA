-- nombre de tabla "sesion_accesos": convencion de gorm para el struct SesionAcceso
-- (snake_case + pluralizacion en ingles -> "sesion_acceso" + "s")
CREATE TABLE sesion_accesos (
    id         BIGSERIAL PRIMARY KEY,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    deleted_at TIMESTAMPTZ,
    acceso_id  BIGINT NOT NULL REFERENCES accesos (id),
    token      TEXT NOT NULL,
    revocada   BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX idx_sesion_accesos_deleted_at ON sesion_accesos (deleted_at);
CREATE INDEX idx_sesion_accesos_acceso_id ON sesion_accesos (acceso_id);
CREATE UNIQUE INDEX idx_sesion_accesos_token ON sesion_accesos (token);
