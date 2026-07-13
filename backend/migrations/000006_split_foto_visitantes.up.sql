-- antes habia una sola foto (foto_url); ahora el kiosko sube dos: la del documento (INE/pasaporte/
-- licencia) y la de la cara de la persona. DEFAULT '' solo para que la columna nueva no rompa el
-- NOT NULL en filas existentes; se quita despues para que todo insert nuevo este obligado a mandarla.
ALTER TABLE visitantes RENAME COLUMN foto_url TO foto_rostro_url;
ALTER TABLE visitantes ADD COLUMN foto_documento_url TEXT NOT NULL DEFAULT '';
ALTER TABLE visitantes ALTER COLUMN foto_documento_url DROP DEFAULT;
