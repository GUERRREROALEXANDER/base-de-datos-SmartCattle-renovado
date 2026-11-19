-- El asistente ve solo la cuenta de la sesion, y nada sensible.
--
-- Es la prueba mas importante de este bloque: un fallo aqui muestra la finca de
-- un cliente a otro, y el texto del asistente no permite notarlo.
--
-- Un usuario sin CREATEROLE instala sin el rol (ver 0033), y entonces no hay nada
-- que probar. CI siempre lo tiene.
SELECT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'smartcattle_assistant') AS has_assistant_role \gset
\if :has_assistant_role
BEGIN;

DO $$
DECLARE
    ana   bigint;
    luis  bigint;
    cam_a bigint;
    cam_l bigint;
BEGIN
    INSERT INTO users (email, password_hash, full_name) VALUES ('t28-ana@x.co', 'h', 'Ana') RETURNING id INTO ana;
    INSERT INTO users (email, password_hash, full_name) VALUES ('t28-luis@x.co', 'h', 'Luis') RETURNING id INTO luis;
    INSERT INTO cameras (name, account_id, display_name) VALUES ('t28-a', ana, 'Corral') RETURNING id INTO cam_a;
    INSERT INTO cameras (name, account_id, display_name) VALUES ('t28-l', luis, 'Potrero') RETURNING id INTO cam_l;

    INSERT INTO detection_logs (camera_id, minute, cattle_lying, cattle_standing, cattle_walking,
                                cattle_unknown, people, observed_at) VALUES
        (cam_a, '2026-03-01 15:00+00', 1, 0, 0, 0, 0, now()),
        (cam_l, '2026-03-01 15:00+00', 0, 0, 0, 0, 2, now()),
        (cam_l, '2026-03-01 15:01+00', 0, 0, 0, 0, 3, now());
    INSERT INTO events (type, camera_id, detected_at) VALUES ('cattle_out_of_zone', cam_l, '2026-03-01 15:00+00');

    -- Los ids pasan como variables de sesion porque el rol no puede leer users.
    PERFORM set_config('t28.ana', ana::text, true);
    PERFORM set_config('t28.luis', luis::text, true);
END $$;

SET LOCAL ROLE smartcattle_assistant;

DO $$
BEGIN
    -- Sin cuenta en la sesion: nada, ni siquiera un error.
    PERFORM set_config('app.current_account_id', '', true);
    ASSERT (SELECT count(*) FROM v_assistant_detections) = 0, 'sin cuenta no deberia ver detecciones';
    ASSERT (SELECT count(*) FROM v_assistant_events) = 0, 'sin cuenta no deberia ver eventos';
    ASSERT (SELECT count(*) FROM assistant_daily_reports('2026-03-01', '2026-03-01')) = 0,
           'sin cuenta no deberia ver informes';

    PERFORM set_config('app.current_account_id', current_setting('t28.ana'), true);
    ASSERT (SELECT count(*) FROM v_assistant_detections) = 1, 'ana deberia ver solo su fila';
    ASSERT (SELECT camera FROM v_assistant_detections) = 'Corral', 'ana deberia ver su camara';
    ASSERT (SELECT count(*) FROM v_assistant_events) = 0, 'ana no deberia ver eventos de luis';
    ASSERT (SELECT camera FROM assistant_daily_reports('2026-03-01', '2026-03-01')) = 'Corral',
           'ana deberia recibir solo su informe';

    PERFORM set_config('app.current_account_id', current_setting('t28.luis'), true);
    ASSERT (SELECT count(*) FROM v_assistant_detections) = 2, 'luis deberia ver sus dos filas';
