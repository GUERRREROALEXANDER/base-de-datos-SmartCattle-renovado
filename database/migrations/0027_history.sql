-- 0027: tablas de historial.
--
-- Hasta aqui la base guardaba solo el presente: el ultimo conteo por camara y
-- el estado actual, sobrescritos. Estas guardan el pasado a un ritmo que cabe
-- en el plan gratuito de Neon:
--
-- - occupancy_samples: una fila por camara y minuto, no por reporte.
-- - camera_status_changes: una fila por cambio de estado, no por reporte.
-- - audit_log: una fila por accion de una persona.
--
-- Las escribe solo el backend. Son las mismas que crea su migracion 0016; da
-- igual cual corra primero.

CREATE TABLE IF NOT EXISTS occupancy_samples (
    camera_id      bigint      NOT NULL REFERENCES cameras (id) ON DELETE CASCADE,
    minute         timestamptz NOT NULL,
    cattle_inside  integer     NOT NULL,
    cattle_outside integer     NOT NULL,
    observed_at    timestamptz NOT NULL,
    -- Empieza por camera_id, asi que sirve tambien de indice de la clave ajena.
    CONSTRAINT occupancy_samples_pkey PRIMARY KEY (camera_id, minute),
    CONSTRAINT occupancy_samples_inside_check  CHECK (cattle_inside >= 0),
    CONSTRAINT occupancy_samples_outside_check CHECK (cattle_outside >= 0)
);
CREATE INDEX IF NOT EXISTS occupancy_samples_minute_idx ON occupancy_samples (minute);

COMMENT ON TABLE occupancy_samples IS
    'Conteo de ganado por camara, uno por minuto: el ultimo observado en ese minuto. Crece ~1 440 filas por camara al dia.';
COMMENT ON COLUMN occupancy_samples.minute IS 'El minuto, con los segundos en cero (UTC).';

CREATE TABLE IF NOT EXISTS camera_status_changes (
