-- NULL = usar el tiempo_espera_min del AccesoConfig del kiosko
ALTER TABLE residentes ADD COLUMN tiempo_espera_min INTEGER;
