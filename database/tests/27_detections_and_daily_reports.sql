-- detection_logs rechaza lo invalido, y el informe diario cuadra.
BEGIN;

DO $$
DECLARE
    cam bigint;
    col text;
BEGIN
    INSERT INTO cameras (name) VALUES ('t27-limites') RETURNING id INTO cam;
    INSERT INTO detection_logs (camera_id, minute, cattle_lying, cattle_standing, cattle_walking,
                                cattle_unknown, people, avg_confidence, observed_at)
    VALUES (cam, '2026-03-01 12:00+00', 0, 0, 0, 0, 0, NULL, now());

    FOREACH col IN ARRAY ARRAY['cattle_lying', 'cattle_standing', 'cattle_walking', 'cattle_unknown', 'people'] LOOP
        BEGIN
            EXECUTE format('UPDATE detection_logs SET %I = -1 WHERE camera_id = $1', col) USING cam;
            ASSERT false, format('%s no deberia aceptar negativos', col);
        EXCEPTION WHEN check_violation THEN NULL;
        END;
    END LOOP;

    BEGIN
        UPDATE detection_logs SET avg_confidence = 1.01 WHERE camera_id = cam;
        ASSERT false, 'avg_confidence no deberia aceptar mas de 1';
    EXCEPTION WHEN check_violation THEN NULL;
    END;
    UPDATE detection_logs SET avg_confidence = 1 WHERE camera_id = cam;
    UPDATE detection_logs SET avg_confidence = 0 WHERE camera_id = cam;

    -- Un minuto por camara: el segundo reporte reescribe, no agrega.
    BEGIN
        INSERT INTO detection_logs (camera_id, minute, cattle_lying, cattle_standing, cattle_walking,
                                    cattle_unknown, people, observed_at)
        VALUES (cam, '2026-03-01 12:00+00', 1, 0, 0, 0, 0, now());
        ASSERT false, 'no deberia haber dos filas por camara y minuto';
    EXCEPTION WHEN unique_violation THEN NULL;
    END;
END $$;

-- La vista detections da una fila por objeto y postura vistos, sin ceros.
DO $$
DECLARE
    cam bigint;
BEGIN
    INSERT INTO cameras (name) VALUES ('t27-vista') RETURNING id INTO cam;
    INSERT INTO detection_logs (camera_id, minute, cattle_lying, cattle_standing, cattle_walking,
                                cattle_unknown, people, observed_at)
    VALUES (cam, '2026-03-01 12:00+00', 2, 0, 1, 4, 3, now());

    ASSERT (SELECT count(*) FROM detections WHERE camera_id = cam) = 4, 'deberia omitir el conteo en cero';
    ASSERT (SELECT detected_count FROM detections
             WHERE camera_id = cam AND object_type = 'cattle' AND posture = 'lying') = 2, 'reses echadas';
    ASSERT (SELECT detected_count FROM detections
             WHERE camera_id = cam AND object_type = 'cattle' AND posture IS NULL) = 4, 'postura desconocida';
    ASSERT (SELECT detected_count FROM detections WHERE camera_id = cam AND object_type = 'person') = 3, 'personas';
    ASSERT NOT EXISTS (SELECT 1 FROM detections WHERE camera_id = cam AND posture = 'standing'),
           'de pie estaba en cero';
    ASSERT (SELECT DISTINCT "timestamp" FROM detections WHERE camera_id = cam) = '2026-03-01 12:00+00',
           'timestamp deberia ser el minuto';
END $$;

-- El dia se corta en la zona pedida y cada cuenta recibe lo suyo.
DO $$
DECLARE
    ana  bigint;
    luis bigint;
    cam  bigint;
    r    record;
BEGIN
    INSERT INTO users (email, password_hash, full_name) VALUES ('t27-ana@x.co', 'h', 'Ana') RETURNING id INTO ana;
    INSERT INTO users (email, password_hash, full_name) VALUES ('t27-luis@x.co', 'h', 'Luis') RETURNING id INTO luis;
    INSERT INTO cameras (name, account_id, display_name) VALUES ('t27-dia', ana, 'Corral') RETURNING id INTO cam;

    INSERT INTO detection_logs (camera_id, minute, cattle_lying, cattle_standing, cattle_walking,
