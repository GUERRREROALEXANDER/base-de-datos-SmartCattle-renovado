-- Cada cuenta tiene sus camaras y no repite nombre entre las suyas.
--
-- cameras.name sigue siendo unico en toda la base: la ingesta del backend usa
-- ON CONFLICT (name), y sin ese UNIQUE falla en cada evento.
BEGIN;

DO $$
DECLARE
    ana  bigint;
    luis bigint;
BEGIN
    INSERT INTO users (email, password_hash, full_name) VALUES ('t26-ana@x.co', 'h', 'Ana') RETURNING id INTO ana;
    INSERT INTO users (email, password_hash, full_name) VALUES ('t26-luis@x.co', 'h', 'Luis') RETURNING id INTO luis;

    INSERT INTO cameras (name, account_id, display_name) VALUES ('t26-a1', ana, 'Corral');
    INSERT INTO cameras (name, account_id, display_name) VALUES ('t26-a2', ana, 'Establo');

    -- Otra cuenta si puede llamarla igual.
    INSERT INTO cameras (name, account_id, display_name) VALUES ('t26-l1', luis, 'Corral');

    -- Una cuenta no puede repetirlo, ni cambiando mayusculas.
    BEGIN
        INSERT INTO cameras (name, account_id, display_name) VALUES ('t26-a3', ana, 'CORRAL');
        ASSERT false, 'una cuenta no deberia repetir el nombre de una camara';
    EXCEPTION WHEN unique_violation THEN NULL;
    END;

    -- Camaras sin dueno o sin nombre no chocan entre si.
    INSERT INTO cameras (name) VALUES ('t26-n1'), ('t26-n2');
    INSERT INTO cameras (name, account_id) VALUES ('t26-a4', ana), ('t26-a5', ana);

    -- Quitarla del tablero libera el nombre, como hace el backend al olvidarla.
    UPDATE cameras SET display_name = NULL, active = FALSE WHERE name = 't26-a2';
    INSERT INTO cameras (name, account_id, display_name) VALUES ('t26-a6', ana, 'Establo');

    -- El identificador global sigue siendo unico.
    BEGIN
