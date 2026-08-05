CREATE TABLE invitaciones (
    id            BIGSERIAL PRIMARY KEY,
    created_at    TIMESTAMPTZ,
    updated_at    TIMESTAMPTZ,
    deleted_at    TIMESTAMPTZ,

    token         VARCHAR(64)  NOT NULL,
    tipo          VARCHAR(20)  NOT NULL DEFAULT 'PERSONAL',
    titular       TEXT         NOT NULL,
    residente_id  BIGINT       NOT NULL,
    destino_id    BIGINT       NOT NULL,
    conteo_usos   INT          NOT NULL DEFAULT 0,
    max_usos      INT,
    expires_at    TIMESTAMPTZ
);

CREATE UNIQUE INDEX idx_invitaciones_token    ON invitaciones (token);
CREATE        INDEX idx_invitaciones_deleted  ON invitaciones (deleted_at);
CREATE        INDEX idx_invitaciones_residente ON invitaciones (residente_id);
