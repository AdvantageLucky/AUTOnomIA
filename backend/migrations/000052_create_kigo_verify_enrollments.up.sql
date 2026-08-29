-- nombre de tabla "kigo_verify_enrollments": convencion de gorm para el
-- struct KigoVerifyEnrollment
CREATE TABLE kigo_verify_enrollments (
    id             BIGSERIAL PRIMARY KEY,
    created_at     TIMESTAMPTZ,
    updated_at     TIMESTAMPTZ,
    deleted_at     TIMESTAMPTZ,
    persona_id     BIGINT NOT NULL REFERENCES personas (id),
    enrollment_id  TEXT NOT NULL,
    webhook_secret TEXT NOT NULL,
    status         TEXT NOT NULL DEFAULT 'PENDING',
    expires_at     TIMESTAMPTZ NOT NULL,
    foto_rostro_url TEXT NOT NULL DEFAULT ''
);

CREATE INDEX idx_kigo_verify_enrollments_deleted_at ON kigo_verify_enrollments (deleted_at);
CREATE INDEX idx_kigo_verify_enrollments_persona_id ON kigo_verify_enrollments (persona_id);
CREATE UNIQUE INDEX idx_kigo_verify_enrollments_enrollment_id ON kigo_verify_enrollments (enrollment_id);
