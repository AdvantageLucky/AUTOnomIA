-- La clave de elector es redundante con la CURP y su OCR es poco confiable
-- (dispara falsos positivos de "OCR sospechoso"); se elimina del todo.
ALTER TABLE visitas DROP COLUMN clave_lector;
