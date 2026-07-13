CREATE TABLE admins (
    id               BIGSERIAL PRIMARY KEY,
    created_at       TIMESTAMPTZ,
    updated_at       TIMESTAMPTZ,
    deleted_at       TIMESTAMPTZ,
    nombre           TEXT NOT NULL,
    apellido_paterno TEXT NOT NULL,
    apellido_materno TEXT NOT NULL,
    correo           TEXT NOT NULL,
    password         TEXT NOT NULL
);

CREATE INDEX idx_admins_deleted_at ON admins (deleted_at);

-- Indice parcial (no global) para que un correo de un admin eliminado (soft delete)
-- pueda volver a registrarse sin chocar con un UNIQUE que cuente filas borradas.
CREATE UNIQUE INDEX idx_admins_correo ON admins (correo) WHERE deleted_at IS NULL;
