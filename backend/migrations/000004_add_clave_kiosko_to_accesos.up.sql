-- DEFAULT '' solo para que las filas existentes (creadas antes de este campo) no violen el NOT NULL;
-- se quita el default despues para que todo insert nuevo este obligado a mandar una clave_kiosko real,
-- igual que ya exige el binding:"required,min=6" de AccesoRequest a nivel de aplicacion.
ALTER TABLE accesos ADD COLUMN clave_kiosko TEXT NOT NULL DEFAULT '';
ALTER TABLE accesos ALTER COLUMN clave_kiosko DROP DEFAULT;
