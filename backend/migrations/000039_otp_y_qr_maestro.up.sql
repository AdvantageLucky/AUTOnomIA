-- El QR personal se firma con una llave maestra de todo el sistema (ver
-- spec §3/§10), no con un secreto por Persona — este campo no tiene función.
ALTER TABLE personas DROP COLUMN IF EXISTS qr_secreto;

CREATE TABLE otp_solicitudes (
    id          BIGSERIAL PRIMARY KEY,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at  TIMESTAMPTZ,
    telefono    TEXT NOT NULL,
    codigo      TEXT NOT NULL,
    expira_en   TIMESTAMPTZ NOT NULL
);

CREATE INDEX idx_otp_solicitudes_telefono ON otp_solicitudes (telefono);
CREATE INDEX idx_otp_solicitudes_deleted_at ON otp_solicitudes (deleted_at);
