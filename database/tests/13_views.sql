-- Las vistas existen y aplican la regla que dicen aplicar.
DO $$
DECLARE
    missing text[];
BEGIN
    SELECT array_agg(name ORDER BY name) INTO missing
    FROM unnest(ARRAY['v_api_events', 'v_active_herd']) AS name
    WHERE to_regclass(name) IS NULL;

    ASSERT missing IS NULL, format('faltan vistas: %s', missing);
END $$;

-- v_api_events excluye las filas que el esquema Event no puede representar.
DO $$
DECLARE
    camera bigint;
    before_count bigint;
BEGIN
    SELECT count(*) INTO before_count FROM v_api_events;
    INSERT INTO cameras (name) VALUES ('test-view') RETURNING id INTO camera;

    -- Fila de otro servicio: sin ai_event_id ni received_at.
    INSERT INTO events (type, camera_id, detected_object, confidence)
    VALUES ('cattle_out_of_zone', camera, 'cow', 0.9);
    -- Fila completa salvo confidence.
    INSERT INTO events (type, camera_id, detected_object, ai_event_id, received_at)
    VALUES ('cattle_out_of_zone', camera, 'cow', gen_random_uuid(), now());
    -- Fila que si cumple.
