-- 01 Market overview: listings, hosts, median price and rating by room type
-- active = at least one review in the last 12 months

SELECT
    room_type,
    COUNT(*)                                                              AS listings,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM mart.listings), 1)     AS pct_of_listings,
    SUM(CASE WHEN is_active THEN 1 ELSE 0 END)                            AS active_listings,
    ROUND(100.0 * SUM(CASE WHEN is_active THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_active,
    COUNT(DISTINCT host_id)                                               AS hosts,
    ROUND(CAST(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price_normal_night) AS numeric)) AS median_price_eur,
    ROUND(CAST(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY rating_overall) AS numeric), 2) AS median_rating,
    ROUND(AVG(CASE WHEN is_active THEN est_nights_booked END))            AS avg_nights_booked_active
FROM mart.listings
GROUP BY room_type

UNION ALL

SELECT
    'ALL LISTINGS',
    COUNT(*),
    100.0,
    SUM(CASE WHEN is_active THEN 1 ELSE 0 END),
    ROUND(100.0 * SUM(CASE WHEN is_active THEN 1 ELSE 0 END) / COUNT(*), 1),
    COUNT(DISTINCT host_id),
    ROUND(CAST(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price_normal_night) AS numeric)),
    ROUND(CAST(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY rating_overall) AS numeric), 2),
    ROUND(AVG(CASE WHEN is_active THEN est_nights_booked END))
FROM mart.listings

ORDER BY listings DESC;
