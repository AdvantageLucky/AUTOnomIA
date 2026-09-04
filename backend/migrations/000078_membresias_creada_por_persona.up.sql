-- Un invitado frecuente lo da de alta un residente por su cuenta, sin pasar
-- por el admin -- pero hasta ahora no quedaba registrado QUIEN lo enrolo, asi
-- que en el dashboard el admin veia el acceso recurrente sin saber quien
-- respondia por esa persona. Solo se llena para membresias creadas por un
-- residente (invitados frecuentes); las de residente real quedan en NULL.
ALTER TABLE membresias ADD COLUMN creada_por_persona_id BIGINT NULL;
CREATE INDEX idx_membresias_creada_por_persona_id ON membresias (creada_por_persona_id);
