-- Staging: booking calendar, one row per listing and night

DROP TABLE IF EXISTS stg.calendar CASCADE;

CREATE TABLE stg.calendar AS
SELECT
    CAST(c.listing_id AS bigint)                AS listing_id,
    CAST(c.date AS date)                        AS night,
    -- false = booked or blocked by the host
    c.available = 't'                           AS is_available,
    CAST(NULLIF(c.minimum_nights, '') AS int)   AS minimum_nights
FROM raw.calendar AS c;

ALTER TABLE stg.calendar ADD PRIMARY KEY (listing_id, night);
