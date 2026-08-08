CREATE TABLE device_authorizations (
    id          BIGSERIAL PRIMARY KEY,
    device_code TEXT        NOT NULL UNIQUE,
    user_code   TEXT        NOT NULL UNIQUE,
    kiosko_id   BIGINT      REFERENCES kioskos(id),
    tenant_id   BIGINT      REFERENCES centros_habitacionales(id),
    status      TEXT        NOT NULL DEFAULT 'pending',
    expires_at  TIMESTAMPTZ NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at  TIMESTAMPTZ
);

CREATE INDEX idx_device_auth_tenant_pending ON device_authorizations(tenant_id, status)
  WHERE deleted_at IS NULL;
