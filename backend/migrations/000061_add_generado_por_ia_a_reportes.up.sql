-- Distingue un reporte que sí escribió el LLM de uno que cayó al
-- heurístico de plantilla (resumirDatosTexto) porque el LLM estaba
-- apagado/inalcanzable o respondió algo inservible -- el dashboard no debe
-- mostrar el heurístico bajo el mismo encabezado de "Análisis de IA".
ALTER TABLE reportes_ia ADD COLUMN generado_por_ia BOOLEAN NOT NULL DEFAULT false;
