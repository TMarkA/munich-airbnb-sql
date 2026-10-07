-- Fact: price, availability and ratings per listing on the scrape date

DROP TABLE IF EXISTS core.fact_listing_snapshot CASCADE;

CREATE TABLE core.fact_listing_snapshot AS
SELECT
    s.listing_id,
    (SELECT MIN(last_scraped) FROM stg.listings)          AS snapshot_date,
    s.price_per_night,
    -- implausible prices: kept, excluded from price statistics
    (s.price_per_night < 15 OR s.price_per_night > 2000)   AS price_is_outlier,
    s.quote_checkin,
    COALESCE(d.is_oktoberfest, false)                      AS quote_in_oktoberfest,
    s.minimum_nights,
    s.availability_365,
    s.number_of_reviews,
    s.rating_overall,
    s.rating_cleanliness,
    s.rating_location,
    s.rating_value,
    s.ia_estimated_nights,
    s.ia_estimated_revenue
FROM stg.listings AS s
LEFT JOIN core.dim_date AS d
       ON d.date = s.quote_checkin;

ALTER TABLE core.fact_listing_snapshot ADD PRIMARY KEY (listing_id);
ALTER TABLE core.fact_listing_snapshot
    ADD FOREIGN KEY (listing_id) REFERENCES core.dim_listing (listing_id);

COMMENT ON TABLE core.fact_listing_snapshot IS 'Price quote, availability, review count and ratings of each listing on the scrape date';
COMMENT ON COLUMN core.fact_listing_snapshot.snapshot_date IS 'First day of the scrape (29 June 2026)';
COMMENT ON COLUMN core.fact_listing_snapshot.price_per_night IS 'Quoted price per night in EUR for quote_checkin (not a list price)';
COMMENT ON COLUMN core.fact_listing_snapshot.quote_in_oktoberfest IS 'The price quote is for a check-in during Oktoberfest';
COMMENT ON COLUMN core.fact_listing_snapshot.ia_estimated_nights IS 'Inside Airbnb''s own estimate of nights booked in the last 365 days';
