-- Los CHECK de rango rechazan de verdad lo que dicen rechazar.
--
-- 03_check_constraints.sql comprueba que existen por nombre. Esto comprueba
-- que funcionan: una constraint se puede redefinir conservando el nombre y
-- dejar de rechazar nada, y entonces la otra comprobacion sigue pasando.
DO $$
DECLARE
    camera bigint;
BEGIN
    INSERT INTO cameras (name) VALUES ('test-ranges') RETURNING id INTO camera;

    -- confidence fuera de 0..1
    BEGIN
        INSERT INTO events (type, camera_id, confidence)
        VALUES ('cattle_out_of_zone', camera, 1.5);
        ASSERT false, 'events acepto confidence mayor que 1';
    EXCEPTION WHEN check_violation THEN NULL;
    END;

    BEGIN
        INSERT INTO events (type, camera_id, confidence)
        VALUES ('cattle_out_of_zone', camera, -0.1);
        ASSERT false, 'events acepto confidence negativa';
    EXCEPTION WHEN check_violation THEN NULL;
    END;

    -- Los limites si entran: 0 y 1 son validos.
    INSERT INTO events (type, camera_id, confidence) VALUES ('cattle_out_of_zone', camera, 0);
    INSERT INTO events (type, camera_id, confidence) VALUES ('cattle_out_of_zone', camera, 1);

    -- Zona con las esquinas invertidas: deja todo el cuadro "fuera" y dispara
    -- una alerta por cada animal visible.
