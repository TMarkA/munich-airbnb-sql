-- One schema per layer: raw -> stg -> core -> mart
-- raw.listings, raw.calendar and raw.reviews are created by etl/load.py from the CSV headers

CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS ref;
CREATE SCHEMA IF NOT EXISTS stg;
CREATE SCHEMA IF NOT EXISTS core;
CREATE SCHEMA IF NOT EXISTS mart;

-- district polygons, filled by etl/load.py
CREATE TABLE IF NOT EXISTS raw.neighbourhoods (
    neighbourhood text    NOT NULL,
    area_km2      numeric NOT NULL,
    geometry      text    NOT NULL
);
