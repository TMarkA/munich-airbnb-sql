-- District dimension: Munich's 25 districts with area

DROP TABLE IF EXISTS core.dim_district CASCADE;

CREATE TABLE core.dim_district AS
SELECT
    COALESCE(r.district, n.neighbourhood)  AS district,
    r.district_no,
    n.area_km2,
    n.geometry
FROM raw.neighbourhoods AS n
LEFT JOIN ref.districts AS r
       ON r.source_name = n.neighbourhood;

ALTER TABLE core.dim_district ADD PRIMARY KEY (district);

COMMENT ON TABLE core.dim_district IS 'City districts with area in km² (computed from the GeoJSON) and polygon';
