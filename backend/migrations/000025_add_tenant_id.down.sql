-- 1. Eliminar la columna tenant_id (y sus índices/restricciones asociados)
ALTER TABLE invitaciones DROP COLUMN tenant_id;
ALTER TABLE reportes_ia DROP COLUMN tenant_id;
ALTER TABLE visitas DROP COLUMN tenant_id;
ALTER TABLE residentes DROP COLUMN tenant_id;
ALTER TABLE destinos DROP COLUMN tenant_id;
ALTER TABLE sesion_kioskos DROP COLUMN tenant_id;
ALTER TABLE kiosko_configs DROP COLUMN tenant_id;
ALTER TABLE kioskos DROP COLUMN tenant_id;
ALTER TABLE admins DROP COLUMN tenant_id;

-- 2. Eliminar la tabla maestra
DROP TABLE IF EXISTS centros_habitacionales;
