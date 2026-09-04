-- Deja que quien RECIBE una invitacion la quite de su propia lista
-- ("invitaciones recibidas" en kigo-app) sin afectar al que la creo -- la
-- misma fila de invitaciones es lo que ve el creador en "mis invitaciones",
-- asi que un DELETE real (o el soft-delete de siempre) la habria ocultado
-- para los dos. Este flag es independiente y solo lo filtra la consulta del
-- lado del invitado.
ALTER TABLE invitaciones ADD COLUMN oculta_para_invitado BOOLEAN NOT NULL DEFAULT false;
