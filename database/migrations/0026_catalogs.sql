-- 0026: catalogos de los valores codificados.
--
-- Una tabla por columna codificada, con la etiqueta en ingles y en espanol. El
-- frontend arma sus listas y etiquetas con ellas (GET /api/catalogs del
-- backend) en vez de tenerlas escritas a mano.
--
-- Sin claves ajenas hacia los catalogos, a proposito: cada columna codificada
-- ya tiene su CHECK, y una clave ajena exigiria un indice en cada una (prueba
-- 05) solo para proteger el borrado de una fila de catalogo, que nadie hace.
--
-- Las filas son las mismas que siembra la migracion 0015 del backend; una
-- prueba del backend compara las dos. ON CONFLICT DO NOTHING: volver a correrla
-- no duplica ni pisa una etiqueta corregida a mano.
--
-- Las etiquetas en espanol llevan tildes. psql en Windows usa la pagina de
-- codigos de la consola, y sin esta linea las guardaria danadas.

SET client_encoding = 'UTF8';

CREATE TABLE IF NOT EXISTS event_types (
    code        text    PRIMARY KEY,
    label       text    NOT NULL,
    label_es    text    NOT NULL,
    description text    NOT NULL,
    sort_order  integer NOT NULL
);

INSERT INTO event_types (code, label, label_es, description, sort_order) VALUES
    ('cattle_out_of_zone', 'Cattle out of zone', 'Ganado fuera de zona', 'An animal was detected outside its camera''s safe zone', 1)
ON CONFLICT (code) DO NOTHING;

COMMENT ON TABLE event_types IS 'Catalogo: valores permitidos de la columna codificada, con etiqueta en ingles y espanol.';

CREATE TABLE IF NOT EXISTS severity_levels (
    code        text    PRIMARY KEY,
    label       text    NOT NULL,
    label_es    text    NOT NULL,
    description text    NOT NULL,
    sort_order  integer NOT NULL
);

INSERT INTO severity_levels (code, label, label_es, description, sort_order) VALUES
    ('low', 'Low', 'Baja', 'Detector confidence below 0.6', 1),
    ('medium', 'Medium', 'Media', 'Detector confidence from 0.6 to 0.9', 2),
    ('high', 'High', 'Alta', 'Detector confidence of 0.9 or more', 3)
ON CONFLICT (code) DO NOTHING;

COMMENT ON TABLE severity_levels IS 'Catalogo: valores permitidos de la columna codificada, con etiqueta en ingles y espanol.';

CREATE TABLE IF NOT EXISTS alert_statuses (
    code        text    PRIMARY KEY,
    label       text    NOT NULL,
    label_es    text    NOT NULL,
    description text    NOT NULL,
    sort_order  integer NOT NULL
);

INSERT INTO alert_statuses (code, label, label_es, description, sort_order) VALUES
    ('open', 'Open', 'Abierta', 'Raised and not yet seen by anyone', 1),
    ('acknowledged', 'Acknowledged', 'Atendida', 'Someone is handling it', 2),
    ('resolved', 'Resolved', 'Resuelta', 'Closed, as handled or as a false alarm', 3)
ON CONFLICT (code) DO NOTHING;

COMMENT ON TABLE alert_statuses IS 'Catalogo: valores permitidos de la columna codificada, con etiqueta en ingles y espanol.';

CREATE TABLE IF NOT EXISTS camera_statuses (
    code        text    PRIMARY KEY,
    label       text    NOT NULL,
    label_es    text    NOT NULL,
    description text    NOT NULL,
    sort_order  integer NOT NULL
);

INSERT INTO camera_statuses (code, label, label_es, description, sort_order) VALUES
