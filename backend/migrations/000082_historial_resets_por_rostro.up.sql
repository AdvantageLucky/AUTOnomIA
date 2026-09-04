-- Tercer tipo de reset (junto a persona_id y curp de la 000080): ancla el
-- reset a un embedding facial, para el caso de un visitante sin cuenta, sin
-- INE y sin invitacion -- lo unico que lo identifica es su rostro (ver
-- HistorialPorRostro). Se guarda el vector completo porque no hay clave de
-- texto exacta que comparar como con CURP: el match es por similitud
-- coseno, igual que el resto del reconocimiento facial.
ALTER TABLE historial_resets ADD COLUMN embedding_rostro FLOAT[];
