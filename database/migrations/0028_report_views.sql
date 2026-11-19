-- 0028: vistas de reportes.
--
-- Consultas listas para quien tenga psql o una herramienta de BI. Los dias se
-- cortan en la zona horaria de la sesion; Neon usa UTC, asi que primero:
--
--     SET TIME ZONE 'America/Bogota';
--
-- Las definiciones son las mismas de la migracion 0017 del backend. Las vistas
-- que leen tablas del backend (security_alerts, farms, lots, video_uploads,
-- video_analyses) se saltan si esas tablas todavia no existen, como 0012.

DO $$
BEGIN
    IF to_regclass('security_alerts') IS NULL THEN
        RAISE NOTICE 'v_alerts_daily omitida: faltan tablas del backend (security_alerts)';
        RETURN;
    END IF;

    CREATE OR REPLACE VIEW v_alerts_daily AS
    SELECT created_at::date AS day,
               severity,
               count(*) AS total,
               count(*) FILTER (WHERE status = 'open') AS open,
               count(*) FILTER (WHERE status = 'acknowledged') AS acknowledged,
               count(*) FILTER (WHERE status = 'resolved') AS resolved
          FROM security_alerts
         GROUP BY 1, 2;
END $$;

DO $$
BEGIN
    IF to_regclass('security_alerts') IS NULL THEN
        RAISE NOTICE 'v_alert_response_times omitida: faltan tablas del backend (security_alerts)';
        RETURN;
    END IF;

    CREATE OR REPLACE VIEW v_alert_response_times AS
    SELECT a.id,
               c.name AS camera,
               a.severity,
               a.status,
               a.created_at,
               round((extract(epoch FROM a.acknowledged_at - a.created_at) / 60)::numeric, 1)
                   AS minutes_to_acknowledge,
               round((extract(epoch FROM a.resolved_at - a.created_at) / 60)::numeric, 1)
                   AS minutes_to_resolve,
               ack.email AS acknowledged_by,
               res.email AS resolved_by
          FROM security_alerts a
          LEFT JOIN cameras c ON c.id = a.camera_id
          LEFT JOIN users ack ON ack.id = a.acknowledged_by
          LEFT JOIN users res ON res.id = a.resolved_by;
END $$;

CREATE OR REPLACE VIEW v_events_daily AS
SELECT e.detected_at::date AS day,
           c.name AS camera,
           e.type AS event_type,
           e.level,
           count(*) AS total,
           round(avg(e.confidence)::numeric, 3) AS avg_confidence
      FROM events e
      JOIN cameras c ON c.id = e.camera_id
     WHERE e.detected_at IS NOT NULL
     GROUP BY 1, 2, 3, 4;

CREATE OR REPLACE VIEW v_occupancy_hourly AS
SELECT c.name AS camera,
           date_trunc('hour', s.minute) AS hour,
