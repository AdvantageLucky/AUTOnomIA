ALTER TABLE visitas ADD COLUMN client_id TEXT;
CREATE UNIQUE INDEX idx_visitas_client_id ON visitas (client_id) WHERE client_id IS NOT NULL;
