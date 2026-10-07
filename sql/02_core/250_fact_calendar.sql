-- Fact: calendar nights; the inner join drops 25 listings missing from the listings file

DROP TABLE IF EXISTS core.fact_calendar CASCADE;

CREATE TABLE core.fact_calendar AS
SELECT
    c.listing_id,
    c.night,
    c.is_available,
    c.minimum_nights
FROM stg.calendar AS c
JOIN core.dim_listing AS l
  ON l.listing_id = c.listing_id;

ALTER TABLE core.fact_calendar ADD PRIMARY KEY (listing_id, night);
ALTER TABLE core.fact_calendar
    ADD FOREIGN KEY (listing_id) REFERENCES core.dim_listing (listing_id),
    ADD FOREIGN KEY (night)      REFERENCES core.dim_date (date);

COMMENT ON TABLE core.fact_calendar IS 'Bookability of every listing for each of the next 365 nights';
COMMENT ON COLUMN core.fact_calendar.is_available IS 'true = still bookable; false = booked or blocked by the host';
