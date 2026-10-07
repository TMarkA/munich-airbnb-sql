-- Summary per district

DROP VIEW IF EXISTS mart.district_summary CASCADE;

CREATE VIEW mart.district_summary AS
SELECT
    d.district,
    d.area_km2,
    COUNT(l.listing_id)                                                AS listings,
    SUM(CASE WHEN l.is_active THEN 1 ELSE 0 END)                       AS active_listings,
    COUNT(l.listing_id) / d.area_km2                                   AS listings_per_km2,
    AVG(CASE WHEN l.room_type = 'Entire home/apt' THEN 1.0 ELSE 0.0 END) AS share_entire_homes,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY l.price_normal_night)  AS median_price,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY l.rating_overall)      AS median_rating,
    SUM(l.est_revenue)                                                 AS est_revenue_12m
FROM core.dim_district AS d
LEFT JOIN mart.listings AS l
       ON l.district = d.district
GROUP BY d.district, d.area_km2;

COMMENT ON VIEW mart.district_summary IS 'Listings, density, median price and estimated revenue per district';
