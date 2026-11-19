-- Lo que install.sql tiene que dejar montado.
--
-- Es la comprobacion que detecta la omision mas probable de este repositorio:
-- agregar una migracion y olvidar la linea en install.sql. Entonces CI pasa
-- (aplica el directorio completo con un bucle) y una base nueva instalada por
-- el camino documentado queda incompleta.
DO $$
DECLARE
    missing text[];
BEGIN
    -- Vistas
    SELECT array_agg(name ORDER BY name) INTO missing
    FROM unnest(ARRAY[
        'v_api_events', 'v_active_herd',
        'detections', 'v_assistant_detections', 'v_assistant_events'
    ]) AS name
    WHERE to_regclass(name) IS NULL;
    ASSERT missing IS NULL, format('faltan vistas: %s', missing);

    -- Indices de las migraciones
    SELECT array_agg(name ORDER BY name) INTO missing
    FROM unnest(ARRAY[
        'events_camera_id_idx', 'events_zone_id_idx', 'events_received_at_idx',
        'animals_camera_id_idx', 'animals_zone_id_idx', 'alerts_event_id_idx',
        'alerts_pending_queue_idx', 'animals_active_by_camera_idx',
        'events_api_listable_idx', 'animals_last_detection_idx',
        'cameras_active_idx', 'events_high_level_idx', 'alerts_sent_at_idx',
        'ix_cameras_account_id', 'cameras_account_display_name_key', 'detection_logs_minute_idx'
    ]) AS name
    WHERE to_regclass(name) IS NULL;
    ASSERT missing IS NULL, format('faltan indices: %s', missing);

    -- Columnas de las migraciones
