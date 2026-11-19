-- 0033: lo que puede leer el asistente de IA.
--
-- El asistente responde con datos de la cuenta de quien pregunta. Si el aislamiento
-- dependiera de que el modelo escriba bien un WHERE, una pregunta mal planteada
-- o una inyeccion en el texto mostraria la finca de otro. Por eso:
--
-- - El rol smartcattle_assistant no tiene permiso sobre ninguna tabla. Solo lee
--   estas vistas, que dejan fuera lo sensible: password_hash, correos,
--   cameras.source y stream_url, que pueden llevar credenciales o abrir video.
-- - Cada vista filtra por la cuenta de la sesion. Sin cuenta devuelve cero filas:
--   un olvido del backend deja al asistente sin datos, no con los de todos.
--
-- El backend abre cada consulta asi, con SQL fijo y parametros, nunca con SQL
-- que haya escrito el modelo (ver docs/asistente.md):
--
--     BEGIN READ ONLY;
--     SET LOCAL ROLE smartcattle_assistant;
--     SELECT set_config('app.current_account_id', $1, true);
--     SELECT ... FROM v_assistant_events WHERE ...;
--     COMMIT;

-- Crear el rol y otorgarlo pide permisos que no todo usuario tiene, y el backend
-- corre esto al arrancar. Solo el asistente depende de ello, asi que sin permisos
-- la migracion avisa y sigue: el resto de la API no debe caerse por esto. Cuando
-- un administrador cree el rol, volver a correr este archivo completa los permisos.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'smartcattle_assistant') THEN
        BEGIN
            CREATE ROLE smartcattle_assistant NOLOGIN;
        EXCEPTION WHEN insufficient_privilege THEN
            RAISE WARNING 'Falta el rol smartcattle_assistant y % no puede crearlo. El asistente no funciona hasta que exista. Ver docs/asistente.md', current_user;
            RETURN;
        END;
    END IF;

    -- Desde PostgreSQL 16 quien crea un rol no puede hacer SET ROLE a el sin este
    -- GRANT, y en Neon el backend no es superusuario. Los roles son de todo el
    -- servidor: si otro usuario creo este, no se puede otorgar desde aqui.
    IF NOT pg_has_role(current_user, 'smartcattle_assistant', 'SET') THEN
        BEGIN
            GRANT smartcattle_assistant TO CURRENT_USER;
        EXCEPTION WHEN insufficient_privilege THEN
            RAISE WARNING 'Falta GRANT smartcattle_assistant TO %: lo debe correr quien creo el rol. El asistente no funciona hasta entonces.', current_user;
        END;
    END IF;
END $$;

-- NULLIF: terminada una transaccion con set_config local, la variable queda en ''
-- y no en NULL, y ''::bigint fallaria en vez de no devolver nada.
CREATE OR REPLACE FUNCTION assistant_account_id() RETURNS bigint
LANGUAGE sql
STABLE
AS $$
    SELECT NULLIF(current_setting('app.current_account_id', true), '')::bigint
$$;

COMMENT ON FUNCTION assistant_account_id() IS
    'Cuenta de la sesion del asistente. NULL si el backend no la fijo, y entonces las vistas no devuelven filas.';

-- security_barrier: impide que un filtro con efectos del que consulta vea filas
-- antes de que la vista descarte las de otras cuentas.
CREATE OR REPLACE VIEW v_assistant_detections WITH (security_barrier = true) AS
SELECT coalesce(c.display_name, c.name) AS camera,
       d.object_type,
       d.posture,
       d.detected_count,
       d.avg_confidence,
       d."timestamp"
  FROM detections d
  JOIN cameras c ON c.id = d.camera_id
 WHERE d.account_id = assistant_account_id();

CREATE OR REPLACE VIEW v_assistant_events WITH (security_barrier = true) AS
SELECT e.id,
       coalesce(c.display_name, c.name) AS camera,
       e.type,
       e.level,
       e.detected_object,
       e.confidence,
       e.detected_at
  FROM events e
  JOIN cameras c ON c.id = e.camera_id
