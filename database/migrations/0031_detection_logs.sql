-- 0031: lo que vio la IA, por camara y minuto.
--
-- No es events: events guarda incidentes que dispara una regla. Tampoco es una
-- fila por deteccion: la IA evalua varias veces por segundo y guardarlas serian
-- decenas de miles de filas por camara al dia. Una por minuto, el ultimo reporte
-- de ese minuto, son 1 440 y alcanzan para saber cuanto paso el hato echado o de
-- pie.
--
-- La escribe solo el backend. Es la misma de su migracion 0019_detection_logs;
-- cada lado la crea solo si falta, asi que da igual cual corra primero.

CREATE TABLE IF NOT EXISTS detection_logs (
    camera_id       bigint           NOT NULL REFERENCES cameras (id) ON DELETE CASCADE,
    minute          timestamptz      NOT NULL,
    cattle_lying    integer          NOT NULL,
    cattle_standing integer          NOT NULL,
    cattle_walking  integer          NOT NULL,
    cattle_unknown  integer          NOT NULL,
    people          integer          NOT NULL,
    avg_confidence  double precision,
    observed_at     timestamptz      NOT NULL,
    -- Empieza por camera_id: sirve a la clave ajena, y a la consulta de los
    -- graficos, que pide las camaras de una cuenta en un rango de fechas.
    CONSTRAINT detection_logs_pkey PRIMARY KEY (camera_id, minute),
    CONSTRAINT detection_logs_cattle_lying_check    CHECK (cattle_lying >= 0),
    CONSTRAINT detection_logs_cattle_standing_check CHECK (cattle_standing >= 0),
    CONSTRAINT detection_logs_cattle_walking_check  CHECK (cattle_walking >= 0),
    CONSTRAINT detection_logs_cattle_unknown_check  CHECK (cattle_unknown >= 0),
    CONSTRAINT detection_logs_people_check          CHECK (people >= 0),
    CONSTRAINT detection_logs_avg_confidence_check  CHECK (avg_confidence BETWEEN 0 AND 1)
);

-- Consulta: la retencion y lo que mira todas las camaras a la vez.
--     DELETE FROM detection_logs WHERE minute < $1
CREATE INDEX IF NOT EXISTS detection_logs_minute_idx ON detection_logs (minute);

-- La misma forma de consultar que events: una fila por objeto y postura vistos,
-- sin filas en cero. No guarda nada; lee detection_logs.
