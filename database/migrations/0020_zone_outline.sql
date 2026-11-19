-- 0020: zones.outline, la zona segura como poligono.
--
-- `zones` guarda un rectangulo: cuatro numeros. El frontend ya sabe dibujar y
-- editar un poligono (`SafeZone.outline`), y un potrero real no es rectangular
-- -- sigue una cerca, un camino o un arroyo. Con solo el rectangulo, encerrar
-- el potrero obliga a dejar fuera terreno valido o a meter terreno que no lo
-- es, y cada metro mal clasificado es una alerta falsa o una fuga sin avisar.
--
-- JSONB y no una geometria de PostGIS: Neon no trae PostGIS en el plan
-- gratuito, y para un poligono de cuatro a una docena de vertices
-- normalizados, el indice espacial no aporta nada.
--
-- Formato: [{"x": 0.1, "y": 0.1}, ...], el mismo que ya usa el frontend, con
-- coordenadas de 0 a 1 como el rectangulo.
--
-- Admite NULL, y mientras lo sea manda el rectangulo. Las dos representaciones
-- conviven a proposito: `x_min..y_max` sigue siendo la caja envolvente, que es
-- lo que permite descartar rapido un punto antes de la prueba del poligono.

-- La validacion va en una funcion porque un CHECK no admite subconsultas, y
-- recorrer los vertices exige una. IMMUTABLE es obligatorio para poder usarla
-- en un CHECK: depende solo de su argumento, sin leer tablas ni la hora.
CREATE OR REPLACE FUNCTION is_valid_zone_outline(outline jsonb)
RETURNS boolean
LANGUAGE sql
IMMUTABLE
AS $$
    SELECT outline IS NULL OR (
