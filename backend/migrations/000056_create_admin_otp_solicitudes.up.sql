CREATE TABLE admin_otp_solicitudes (
    id BIGSERIAL PRIMARY KEY,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    deleted_at TIMESTAMPTZ,
    correo TEXT NOT NULL,
    codigo TEXT NOT NULL,
    expira_en TIMESTAMPTZ NOT NULL,
    intentos INT NOT NULL DEFAULT 0
);

CREATE INDEX idx_admin_otp_solicitudes_correo ON admin_otp_solicitudes (correo);
CREATE INDEX idx_admin_otp_solicitudes_deleted_at ON admin_otp_solicitudes (deleted_at);
