-- El PIN ya no lo elige la persona: el backend lo genera (5 dígitos) al
-- unirse a un centro y no vuelve a cambiar. `pin` sigue guardando el hash
-- bcrypt (es lo que compara el kiosko, también offline); `pin_codigo`
-- guarda el código en claro porque la app tiene que poder mostrárselo al
-- residente en "Mi QR".
ALTER TABLE membresias ADD COLUMN pin_codigo TEXT NOT NULL DEFAULT '';
