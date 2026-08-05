-- 1. Crear la tabla raíz para la arquitectura Multi-tenant
CREATE TABLE centros_habitacionales (
    id         BIGSERIAL PRIMARY KEY,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    nombre     TEXT NOT NULL,
    direccion  TEXT NOT NULL DEFAULT ''
);

CREATE INDEX idx_centros_habitacionales_deleted_at ON centros_habitacionales (deleted_at);

-- 2. Insertar el "Tenant Cero" (Fraccionamiento Legado)
-- Esto crea el registro que absorberá todos los datos huérfanos actuales
INSERT INTO centros_habitacionales (nombre, direccion) 
VALUES ('Fraccionamiento Original', 'Configuración pendiente');

-- 3. Añadir la columna tenant_id como NULLABLE temporalmente
-- Esto evita que Postgres rechace la migración por romper la regla NOT NULL
ALTER TABLE admins ADD COLUMN tenant_id BIGINT REFERENCES centros_habitacionales(id);
ALTER TABLE kioskos ADD COLUMN tenant_id BIGINT REFERENCES centros_habitacionales(id);
ALTER TABLE kiosko_configs ADD COLUMN tenant_id BIGINT REFERENCES centros_habitacionales(id);
ALTER TABLE sesion_kioskos ADD COLUMN tenant_id BIGINT REFERENCES centros_habitacionales(id);
ALTER TABLE destinos ADD COLUMN tenant_id BIGINT REFERENCES centros_habitacionales(id);
ALTER TABLE residentes ADD COLUMN tenant_id BIGINT REFERENCES centros_habitacionales(id);
ALTER TABLE visitas ADD COLUMN tenant_id BIGINT REFERENCES centros_habitacionales(id);
ALTER TABLE reportes_ia ADD COLUMN tenant_id BIGINT REFERENCES centros_habitacionales(id);
ALTER TABLE invitaciones ADD COLUMN tenant_id BIGINT REFERENCES centros_habitacionales(id);

-- 4. Hacer el Backfill (Asignar los datos existentes al Tenant Cero)
UPDATE admins SET tenant_id = (SELECT id FROM centros_habitacionales LIMIT 1);
UPDATE kioskos SET tenant_id = (SELECT id FROM centros_habitacionales LIMIT 1);
UPDATE kiosko_configs SET tenant_id = (SELECT id FROM centros_habitacionales LIMIT 1);
UPDATE sesion_kioskos SET tenant_id = (SELECT id FROM centros_habitacionales LIMIT 1);
UPDATE destinos SET tenant_id = (SELECT id FROM centros_habitacionales LIMIT 1);
UPDATE residentes SET tenant_id = (SELECT id FROM centros_habitacionales LIMIT 1);
UPDATE visitas SET tenant_id = (SELECT id FROM centros_habitacionales LIMIT 1);
UPDATE reportes_ia SET tenant_id = (SELECT id FROM centros_habitacionales LIMIT 1);
UPDATE invitaciones SET tenant_id = (SELECT id FROM centros_habitacionales LIMIT 1);

-- 5. Bloquear la base de datos (Aplicar NOT NULL)
-- Ahora que ninguna fila es nula, hacemos obligatoria la relación
ALTER TABLE admins ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE kioskos ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE kiosko_configs ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE sesion_kioskos ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE destinos ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE residentes ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE visitas ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE reportes_ia ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE invitaciones ALTER COLUMN tenant_id SET NOT NULL;

-- 6. Crear los índices para el Tenant ID
-- Esto es CRÍTICO para el rendimiento, ya que todas las queries filtrarán por esta columna
CREATE INDEX idx_admins_tenant_id ON admins (tenant_id);
CREATE INDEX idx_kioskos_tenant_id ON kioskos (tenant_id);
CREATE INDEX idx_kiosko_configs_tenant_id ON kiosko_configs (tenant_id);
CREATE INDEX idx_sesion_kioskos_tenant_id ON sesion_kioskos (tenant_id);
CREATE INDEX idx_destinos_tenant_id ON destinos (tenant_id);
CREATE INDEX idx_residentes_tenant_id ON residentes (tenant_id);
CREATE INDEX idx_visitas_tenant_id ON visitas (tenant_id);
CREATE INDEX idx_reportes_ia_tenant_id ON reportes_ia (tenant_id);
CREATE INDEX idx_invitaciones_tenant_id ON invitaciones (tenant_id);
