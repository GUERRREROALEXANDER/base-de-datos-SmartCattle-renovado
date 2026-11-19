-- Historial, catalogos y vistas de reportes (migraciones 0025 a 0028).
--
-- Que existen, que los catalogos no se duplican al aplicar dos veces, y que
-- las tablas de historial rechazan lo que dicen rechazar.
DO $$
DECLARE
    missing text[];
BEGIN
    SELECT array_agg(name ORDER BY name) INTO missing
    FROM unnest(ARRAY[
        'event_types', 'severity_levels', 'alert_statuses', 'camera_statuses',
        'lot_kinds', 'user_roles', 'animal_statuses', 'video_upload_statuses',
        'occupancy_samples', 'camera_status_changes', 'audit_log',
        -- Las tres vistas que no dependen de tablas del backend.
        'v_events_daily', 'v_occupancy_hourly', 'v_camera_status_periods'
    ]) AS name
    WHERE to_regclass(name) IS NULL;
    ASSERT missing IS NULL, format('faltan tablas o vistas: %s', missing);

    SELECT array_agg(name ORDER BY name) INTO missing
    FROM unnest(ARRAY[
        'occupancy_samples_minute_idx', 'camera_status_changes_camera_id_changed_at_idx',
        'audit_log_created_at_idx', 'audit_log_actor_id_idx', 'audit_log_action_created_at_idx'
    ]) AS name
    WHERE to_regclass(name) IS NULL;
    ASSERT missing IS NULL, format('faltan indices del historial: %s', missing);
END $$;

-- Cada catalogo tiene sus filas una sola vez, aunque CI aplique todo dos veces.
DO $$
BEGIN
    ASSERT (SELECT count(*) FROM event_types)           = 1, 'event_types';
    ASSERT (SELECT count(*) FROM severity_levels)       = 3, 'severity_levels';
    ASSERT (SELECT count(*) FROM alert_statuses)        = 3, 'alert_statuses';
    ASSERT (SELECT count(*) FROM camera_statuses)       = 3, 'camera_statuses';
    ASSERT (SELECT count(*) FROM lot_kinds)             = 4, 'lot_kinds';
    ASSERT (SELECT count(*) FROM user_roles)            = 2, 'user_roles';
    ASSERT (SELECT count(*) FROM animal_statuses)       = 3, 'animal_statuses';
    ASSERT (SELECT count(*) FROM video_upload_statuses) = 5, 'video_upload_statuses';

    -- Los roles del catalogo son los que admite users.role.
    ASSERT (SELECT array_agg(code ORDER BY code) FROM user_roles) = ARRAY['owner', 'worker'],
           'user_roles no coincide con users.role';
    -- Las tildes llegaron enteras.
    ASSERT (SELECT label_es FROM user_roles WHERE code = 'owner') = 'Dueño',
