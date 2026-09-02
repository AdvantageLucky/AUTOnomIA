-- El teléfono de contacto pasó a vivir en centros_habitacionales (un solo
-- número por centro, no uno por kiosko) -- ver migración 000071, que ya
-- copió el dato antes de este drop.
ALTER TABLE kiosko_configs DROP COLUMN telefono_contacto;
