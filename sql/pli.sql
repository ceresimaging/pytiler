CREATE OR REPLACE
FUNCTION public.pli(z integer, x integer, y integer)
RETURNS bytea
AS $$
    WITH
    bounds AS (
      SELECT ST_TileEnvelope(z, x, y) AS geom
    ),
    pli AS (
      SELECT p.*
      FROM "dc9e640b-6cc4-4b5d-8541-973170b01bdf" p, bounds
      WHERE p.geom::geometry && ST_Transform(bounds.geom, 4326)
    ),
    mvtgeom AS (
      SELECT ST_AsMVTGeom(ST_Transform(t.geom::geometry, 3857), bounds.geom) AS geom,
        t.value, t.color
      FROM pli t, bounds
      WHERE ST_Intersects(t.geom::geometry, ST_Transform(bounds.geom, 4326))
    )
    SELECT ST_AsMVT(mvtgeom, 'public.pli') FROM mvtgeom;
$$
LANGUAGE 'sql'
STABLE
PARALLEL SAFE;