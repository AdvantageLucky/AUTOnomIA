-- Distingue un residente real de un "invitado frecuente" (acceso recurrente
-- por reconocimiento facial que un residente le da a alguien, revocable por
-- ese mismo residente) -- reusa el mecanismo de match facial de Membresia,
-- no crea uno paralelo.
--
-- Idempotente a proposito: la migracion 000037 (crear membresias) se edito
-- en algun punto para ya incluir esta misma columna desde el CREATE TABLE
-- -- en una base de datos ya migrada antes de ese cambio, migrate corre esta
-- ALTER normal; en una base de datos nueva desde cero, la columna ya existe
-- por la 000037 y este bloque no hace nada. Sin el IF NOT EXISTS, una
-- migracion desde cero (como para probar todo limpio antes de una demo)
-- truena aqui con "column rol already exists" y deja el historial de
-- migraciones marcado como dirty.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'membresias' AND column_name = 'rol'
    ) THEN
        ALTER TABLE membresias ADD COLUMN rol TEXT NOT NULL DEFAULT 'residente';
    END IF;
END $$;
