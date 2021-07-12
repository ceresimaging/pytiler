CREATE OR REPLACE
FUNCTION public.markers(
            z integer, x integer, y integer,
            marker_type text default 'note')
RETURNS bytea
AS $$
    WITH
    bounds AS (
      SELECT ST_TileEnvelope(z, x, y) AS geom
    ),
    mvtgeom AS (
      SELECT ST_AsMVTGeom(ST_Transform(t.geometry, 3857), bounds.geom) AS geom,
        t.type
      FROM markers t, bounds
      WHERE ST_Intersects(t.geometry, ST_Transform(bounds.geom, 4326))
      AND t.type = marker_type
    )
    SELECT ST_AsMVT(mvtgeom, 'public.markers') FROM mvtgeom;
$$
LANGUAGE 'sql'
STABLE
PARALLEL SAFE;