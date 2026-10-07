-- Main view: one row per listing with occupancy and revenue estimates
-- nights booked = reviews in last 12 months / 0.5 * max(3, minimum nights), capped at 255

DROP VIEW IF EXISTS mart.listings CASCADE;

CREATE VIEW mart.listings AS
WITH reviews_12m AS (
    SELECT
        f.listing_id,
        COUNT(*) AS reviews_12m
    FROM core.fact_listing_snapshot AS f
    JOIN core.fact_review AS r
      ON r.listing_id = f.listing_id
    WHERE r.review_date >  f.snapshot_date - 365
      AND r.review_date <= f.snapshot_date
    GROUP BY f.listing_id
),
base AS (
    SELECT
        l.listing_id,
        l.listing_name,
        l.district,
        l.latitude,
        l.longitude,
        l.property_type,
        l.room_type,
        l.size_class,
        l.accommodates,
        l.bedrooms,
        l.beds,
        l.has_air_conditioning,
        h.host_id,
        h.host_type,
        h.is_superhost,
        f.price_per_night,
        f.price_is_outlier,
        f.quote_checkin,
        f.quote_in_oktoberfest,
        f.minimum_nights,
        f.availability_365,
        f.number_of_reviews,
        f.rating_overall,
        f.rating_cleanliness,
        f.rating_location,
        f.rating_value,
        l.first_review,
        l.last_review,
        COALESCE(r.reviews_12m, 0)                                     AS reviews_12m,
        CAST(LEAST(ROUND(COALESCE(r.reviews_12m, 0) / 0.5
                         * GREATEST(3, COALESCE(f.minimum_nights, 3))), 255) AS int)
                                                                       AS est_nights_booked,
        f.ia_estimated_nights,
        f.ia_estimated_revenue
    FROM core.fact_listing_snapshot AS f
    JOIN core.dim_listing AS l ON l.listing_id = f.listing_id
    JOIN core.dim_host    AS h ON h.host_id    = l.host_id
    LEFT JOIN reviews_12m AS r ON r.listing_id = f.listing_id
)
-- business rules
SELECT
    b.*,
    b.reviews_12m > 0                                                  AS is_active,
    CASE WHEN NOT b.price_is_outlier
         THEN b.est_nights_booked * b.price_per_night
    END                                                                AS est_revenue,
    CASE WHEN NOT b.price_is_outlier AND NOT b.quote_in_oktoberfest
         THEN b.price_per_night
    END                                                                AS price_normal_night,
    b.room_type = 'Entire home/apt' AND b.est_nights_booked > 56       AS exceeds_56_nights,
    CASE
        WHEN b.price_per_night IS NULL OR b.price_is_outlier THEN NULL
        WHEN b.price_per_night <  75 THEN '1 under 75'
        WHEN b.price_per_night < 125 THEN '2 75-124'
        WHEN b.price_per_night < 200 THEN '3 125-199'
        WHEN b.price_per_night < 350 THEN '4 200-349'
        ELSE '5 350+'
    END                                                                AS price_band
FROM base AS b;

COMMENT ON VIEW mart.listings IS 'One row per listing with host, district, price and occupancy estimates';
COMMENT ON COLUMN mart.listings.est_nights_booked IS 'Estimated nights booked in the last 12 months (San Francisco model, from reviews)';
COMMENT ON COLUMN mart.listings.price_normal_night IS 'Price for statistics: NULL for outliers and for quotes on Oktoberfest dates';
COMMENT ON COLUMN mart.listings.exceeds_56_nights IS 'Entire home with more than 56 estimated nights: above Munich''s 8-week limit without permit';
COMMENT ON COLUMN mart.listings.is_active IS 'At least one review in the 12 months before the scrape';
