ALTER TABLE kiosko_configs
ADD COLUMN screensaver_habilitado BOOLEAN NOT NULL DEFAULT true,
ADD COLUMN modo_captura_nombre VARCHAR(50) NOT NULL DEFAULT 'TECLADO',
ADD COLUMN mostrar_nombre_invitado BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN tiempo_exito_seg INT NOT NULL DEFAULT 5,
ADD COLUMN lector_fisico_habilitado BOOLEAN NOT NULL DEFAULT false;
