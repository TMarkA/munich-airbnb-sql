-- Host dimension: host type by number of listings in Munich

DROP TABLE IF EXISTS core.dim_host CASCADE;

CREATE TABLE core.dim_host AS
SELECT
    host_id,
    BOOL_OR(host_is_superhost)        AS is_superhost,
    MAX(host_listings_in_munich)      AS listings_in_munich,
    CASE
        WHEN MAX(host_listings_in_munich) >= 5 THEN '3 Professional (5+)'
        WHEN MAX(host_listings_in_munich) >= 2 THEN '2 Multi (2-4)'
        ELSE '1 Single listing'
    END                               AS host_type
FROM stg.listings
GROUP BY host_id;

ALTER TABLE core.dim_host ADD PRIMARY KEY (host_id);

COMMENT ON TABLE core.dim_host IS 'One row per host with host type (single / multi / professional)';
COMMENT ON COLUMN core.dim_host.host_type IS '1 Single listing / 2 Multi (2-4) / 3 Professional (5+ listings in Munich)';
