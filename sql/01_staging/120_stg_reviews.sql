-- Staging: reviews (names and texts removed in etl/prepare_data.py)

DROP TABLE IF EXISTS stg.reviews CASCADE;

CREATE TABLE stg.reviews AS
SELECT
    CAST(r.id AS bigint)           AS review_id,
    CAST(r.listing_id AS bigint)   AS listing_id,
    CAST(r.reviewer_id AS bigint)  AS reviewer_id,
    CAST(r.date AS date)           AS review_date
FROM raw.reviews AS r;

ALTER TABLE stg.reviews ADD PRIMARY KEY (review_id);
