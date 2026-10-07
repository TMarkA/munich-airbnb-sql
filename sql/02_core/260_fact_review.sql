-- Fact: reviews; reviews of removed listings are kept and flagged

DROP TABLE IF EXISTS core.fact_review CASCADE;

CREATE TABLE core.fact_review AS
SELECT
    r.review_id,
    r.listing_id,
    r.reviewer_id,
    r.review_date,
    l.listing_id IS NOT NULL     AS listing_exists
FROM stg.reviews AS r
LEFT JOIN core.dim_listing AS l
       ON l.listing_id = r.listing_id;

ALTER TABLE core.fact_review ADD PRIMARY KEY (review_id);
ALTER TABLE core.fact_review
    ADD FOREIGN KEY (review_date) REFERENCES core.dim_date (date);

COMMENT ON TABLE core.fact_review IS 'Every review (date, listing, pseudonymous reviewer id); text removed for privacy';
COMMENT ON COLUMN core.fact_review.listing_exists IS 'false if the listing has since left Airbnb (review kept as past demand)';
