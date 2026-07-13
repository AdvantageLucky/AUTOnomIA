CREATE TABLE accesos (
    id         BIGSERIAL PRIMARY KEY,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    deleted_at TIMESTAMPTZ,
    nombre     TEXT NOT NULL,
    ubicacion  TEXT,
    admin_id   BIGINT NOT NULL REFERENCES admins (id)
);

CREATE INDEX idx_accesos_deleted_at ON accesos (deleted_at);

-- admin_id no esta marcado "index" en el struct Go, pero todo query del repository
-- filtra por admin_id (FindAllByAdminID, FindByIDAndAdminID) asi que se indexa a nivel DB.
CREATE INDEX idx_accesos_admin_id ON accesos (admin_id);
