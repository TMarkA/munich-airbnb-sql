-- Staging: typed and cleaned listings, one row per listing

DROP TABLE IF EXISTS stg.listings CASCADE;

CREATE TABLE stg.listings AS
SELECT
    CAST(l.id AS bigint)                                          AS listing_id,
    TRIM(l.name)                                                  AS listing_name,
    CAST(l.host_id AS bigint)                                     AS host_id,
    l.host_is_superhost = 't'                                     AS host_is_superhost,
    CAST(l.calculated_host_listings_count AS int)                 AS host_listings_in_munich,
    COALESCE(d.district, l.neighbourhood_cleansed)                AS district,
    CAST(l.latitude AS numeric)                                   AS latitude,
    CAST(l.longitude AS numeric)                                  AS longitude,
    l.property_type,
    l.room_type,
    CAST(NULLIF(l.accommodates, '') AS int)                       AS accommodates,
    l.bathrooms_text,
    CAST(NULLIF(l.bedrooms, '') AS int)                           AS bedrooms,
    CAST(NULLIF(l.beds, '') AS int)                               AS beds,
    -- check for wifi, kitchen, AC
    l.amenities LIKE '%"Wifi"%'                                   AS has_wifi,
    l.amenities LIKE '%"Kitchen"%'                                AS has_kitchen,
    l.amenities LIKE '%"Air conditioning"%'                       AS has_air_conditioning,
    -- '$1,234.50' -> 1234.50 (currency is EUR)
    CAST(NULLIF(REPLACE(REPLACE(l.price, '$', ''), ',', ''), '') AS numeric) AS price_per_night,
    -- the price is a quote for this check-in date
    CAST(NULLIF(l.price_quote_checkin_date, '') AS date)          AS quote_checkin,
    CAST(NULLIF(l.minimum_nights, '') AS int)                     AS minimum_nights,
    CAST(NULLIF(l.availability_365, '') AS int)                   AS availability_365,
    CAST(NULLIF(l.number_of_reviews, '') AS int)                  AS number_of_reviews,
    CAST(NULLIF(l.first_review, '') AS date)                      AS first_review,
    CAST(NULLIF(l.last_review, '') AS date)                       AS last_review,
    CAST(NULLIF(l.review_scores_rating, '') AS numeric)           AS rating_overall,
    CAST(NULLIF(l.review_scores_cleanliness, '') AS numeric)      AS rating_cleanliness,
    CAST(NULLIF(l.review_scores_location, '') AS numeric)         AS rating_location,
    CAST(NULLIF(l.review_scores_value, '') AS numeric)            AS rating_value,
    CAST(NULLIF(l.estimated_occupancy_l365d, '') AS int)          AS ia_estimated_nights,
    CAST(NULLIF(l.estimated_revenue_l365d, '') AS numeric)        AS ia_estimated_revenue,
    CAST(l.last_scraped AS date)                                  AS last_scraped
FROM raw.listings AS l
-- official district names
LEFT JOIN ref.districts AS d
       ON d.source_name = l.neighbourhood_cleansed;

ALTER TABLE stg.listings ADD PRIMARY KEY (listing_id);

COMMENT ON TABLE stg.listings IS 'Typed and cleaned listings; price = quote for the date quote_checkin';
