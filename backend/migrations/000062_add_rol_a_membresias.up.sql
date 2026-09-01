-- Distingue un residente real de un "invitado frecuente" (acceso recurrente
-- por reconocimiento facial que un residente le da a alguien, revocable por
-- ese mismo residente) -- reusa el mecanismo de match facial de Membresia,
-- no crea uno paralelo.
ALTER TABLE membresias ADD COLUMN rol TEXT NOT NULL DEFAULT 'residente';
