CREATE TABLE visitantes (
    id             BIGSERIAL PRIMARY KEY,
    created_at     TIMESTAMPTZ,
    updated_at     TIMESTAMPTZ,
    deleted_at     TIMESTAMPTZ,
    nombre         TEXT NOT NULL,
    tipo_documento TEXT NOT NULL CHECK (tipo_documento IN ('INE', 'PASAPORTE', 'LICENCIA')),
    clave_lector   TEXT NOT NULL,
    curp           TEXT NOT NULL,
    foto_url       TEXT NOT NULL,
    acceso_id      BIGINT NOT NULL REFERENCES accesos (id)
);

CREATE INDEX idx_visitantes_deleted_at ON visitantes (deleted_at);
CREATE INDEX idx_visitantes_acceso_id ON visitantes (acceso_id);

-- BuscarHistorialVisitante filtra por curp; se indexa para que esa busqueda no haga seq scan.
CREATE INDEX idx_visitantes_curp ON visitantes (curp);
