-- ultimo_ping: heartbeat del kiosko -- se actualiza en cada POST /kioskos/:id/ping
-- (el kiosko ya hace polling de conectividad cada 8s, este endpoint reutiliza
-- ese mismo ciclo) para que el dashboard admin sepa si un kiosko sigue vivo
-- sin depender de que alguien lo mire en persona.
ALTER TABLE kioskos ADD COLUMN ultimo_ping TIMESTAMPTZ;

-- telefono_contacto: numero del vigilante/admin que el kiosko muestra en el
-- boton "hablar con el administrador" -- se guarda en la config, no en el
-- Kiosko, porque ya es donde vive todo lo que la app del kiosko renderiza.
ALTER TABLE kiosko_configs ADD COLUMN telefono_contacto TEXT NOT NULL DEFAULT '';
