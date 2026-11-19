-- Las consultas de docs/consultas.md se ejecutan.
--
-- Un recetario es documentacion que caduca en silencio: se renombra una
-- columna, se cambia una vista, y la consulta sigue publicada y ya no corre.
-- Aqui se ejecuta cada una contra el esquema real.
--
-- No se comprueba el resultado, solo que la consulta es valida: con la base
-- vacia casi todas devuelven cero filas, y exigir un resultado concreto
-- obligaria a sembrar datos y volveria fragil la comprobacion.

DO $$
BEGIN
    -- Los ultimos eventos, legibles.
    PERFORM detected_at, camera_name, detected_object, round(confidence::numeric, 2)
    FROM v_api_events ORDER BY detected_at DESC LIMIT 50;

    -- Alertas por dia, con los dias vacios incluidos.
    PERFORM dia::date, count(e.id)
    FROM generate_series(now() - interval '14 days', now(), interval '1 day') AS dia
    LEFT JOIN v_api_events e ON date_trunc('day', e.detected_at) = date_trunc('day', dia)
    GROUP BY dia;

    -- Animales que no se ven desde hace mucho.
    PERFORM tag, name, camera_name, unseen_for
    FROM v_active_herd
    WHERE last_detection IS NULL OR last_detection < now() - interval '2 days';

    -- La cola de envio.
    PERFORM a.id, a.channel, now() - a.created_at, e.type, c.name
    FROM alerts a
