ALTER TABLE centros_habitacionales ADD COLUMN telefono_contacto TEXT NOT NULL DEFAULT '';

-- Migra el primer telefono_contacto no vacío que tenga cada tenant desde sus
-- kioskos -- evita que instalaciones ya configuradas pierdan el dato con el
-- cambio a un solo campo por centro.
UPDATE centros_habitacionales AS c
SET telefono_contacto = sub.telefono_contacto
FROM (
    SELECT DISTINCT ON (kioskos.tenant_id) kioskos.tenant_id, kiosko_configs.telefono_contacto
    FROM kiosko_configs
    JOIN kioskos ON kioskos.id = kiosko_configs.kiosko_id
    WHERE kiosko_configs.telefono_contacto <> ''
    ORDER BY kioskos.tenant_id, kiosko_configs.id
) AS sub
WHERE sub.tenant_id = c.id;
