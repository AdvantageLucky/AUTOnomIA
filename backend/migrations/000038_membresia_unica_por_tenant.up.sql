CREATE UNIQUE INDEX idx_membresias_persona_tenant ON membresias (persona_id, tenant_id) WHERE deleted_at IS NULL;
