CREATE TABLE acceso_configs (
    id                    BIGSERIAL PRIMARY KEY,
    created_at            TIMESTAMPTZ,
    updated_at            TIMESTAMPTZ,
    deleted_at            TIMESTAMPTZ,
    acceso_id             BIGINT NOT NULL UNIQUE REFERENCES accesos (id),

    -- Apariencia del kiosko
    color_kiosko          TEXT NOT NULL DEFAULT 'oscuro',
    idioma_kiosko         TEXT NOT NULL DEFAULT 'es',

    -- Bitácora para visitantes inesperados
    foto_placa_visitante  BOOLEAN NOT NULL DEFAULT false,
    foto_rostro_visitante BOOLEAN NOT NULL DEFAULT true,
    foto_ine_visitante    BOOLEAN NOT NULL DEFAULT true,

    -- Bitácora para invitados con QR
    foto_placa_invitado   BOOLEAN NOT NULL DEFAULT false,
    foto_rostro_invitado  BOOLEAN NOT NULL DEFAULT false,
    foto_ine_invitado     BOOLEAN NOT NULL DEFAULT false,

    -- Comportamiento de solicitudes
    tiempo_espera_min     INTEGER NOT NULL DEFAULT 5,
    horario_inicio        TEXT NOT NULL DEFAULT '00:00',
    horario_fin           TEXT NOT NULL DEFAULT '23:59',
    mensaje_bienvenida    TEXT NOT NULL DEFAULT ''
);

CREATE INDEX idx_acceso_configs_deleted_at ON acceso_configs (deleted_at);

-- Insertar config con defaults para todos los accesos que ya existen
INSERT INTO acceso_configs (acceso_id, created_at, updated_at)
SELECT id, NOW(), NOW() FROM accesos WHERE deleted_at IS NULL;
