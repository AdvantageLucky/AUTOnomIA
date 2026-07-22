CREATE TABLE reportes_ia (
    id SERIAL PRIMARY KEY,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    periodo_inicio TIMESTAMPTZ NOT NULL,
    periodo_fin TIMESTAMPTZ NOT NULL,
    texto TEXT NOT NULL,
    datos_raw JSONB
);
