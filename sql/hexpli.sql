-- Given an input tile, generate the covering hexagons,
-- spatially join to specified PLI table, calculate
-- value and color in each hexagon, and generate MVT
-- output of the result. Step parameter determines
-- how many hexagons to generate per tile.
DROP FUNCTION IF EXISTS public.hexpli;
CREATE FUNCTION public.hexpli(z integer, x integer, y integer, step integer default 4)
RETURNS bytea
AS $$
    WITH
    bounds AS (
        SELECT ST_TileEnvelope(z, x, y) AS geom
    ),
    pli AS (
        SELECT ST_Transform(p.geom::geometry, 3857) as geom, p.value, p.color
        FROM "dc9e640b-6cc4-4b5d-8541-973170b01bdf" p, bounds
        WHERE p.geom::geometry && ST_Transform(bounds.geom, 4326)
    ),
    rows AS (
        SELECT Avg(value) as value, mode() WITHIN GROUP (ORDER BY color) as color, h.i, h.j, h.geom
        FROM TileHexagons(z, x, y, step) h
        JOIN pli n
        ON ST_Intersects(n.geom, h.geom)
        GROUP BY h.i, h.j, h.geom
    ),
    mvt AS (
        SELECT ST_AsMVTGeom(rows.geom, bounds.geom) AS geom, rows.value, rows.color
        FROM rows, bounds
    )
    SELECT ST_AsMVT(mvt, 'public.hexpli') FROM mvt;
$$
LANGUAGE 'sql'

-- AS $$
-- DECLARE
--     tile bytea;
-- BEGIN
--     EXECUTE format('
--         WITH
--             bounds AS (
--                 -- Convert tile coordinates to web mercator tile bounds
--                 SELECT ST_TileEnvelope(%s, %s, %s) AS geom
--             ),
--             trees AS (
--                 SELECT value, color, geom::geometry geom
--                 FROM %I
--             ),
--             rows AS (
--                 -- Average value and mode color grouped by hex
--                 SELECT Avg(value) as value, mode() WITHIN GROUP (ORDER BY color) as color, h.i, h.j, h.geom
--                 -- All the hexes that interact with this tile
--                 FROM TileHexagons(%s, %s, %s, %s) h
--                 -- All the populated places
--                 JOIN trees n
--                 -- Transform the hex into the SRS (4326 in this case)
--                 -- of the table of interest
--                 ON ST_Intersects(n.geom::geometry, ST_Transform(h.geom, 4326))
--                 GROUP BY h.i, h.j, h.geom
--             ),
--             mvt AS (
--                 -- Usual tile processing, ST_AsMVTGeom simplifies, quantizes,
--                 -- and clips to tile boundary
--                 SELECT ST_AsMVTGeom(rows.geom, bounds.geom) AS geom,
--                     rows.value, rows.color, rows.i, rows.j
--                 FROM rows, bounds
--             )
--         -- Generate MVT encoding of final input record
--         SELECT ST_AsMVT(mvt, ''%s'') FROM mvt
--     ', z, x, y, 'dc9e640b-6cc4-4b5d-8541-973170b01bdf', z, x, y, step, 'hexpli') INTO tile;
--     RETURN tile;
-- END;
-- $$
-- LANGUAGE 'plpgsql'
STABLE
STRICT
PARALLEL SAFE;
