-- 02 Listing density, price and revenue by district

SELECT
    RANK() OVER (ORDER BY listings_per_km2 DESC)            AS density_rank,
    district,
    listings,
    active_listings,
    ROUND(listings_per_km2, 1)                              AS listings_per_km2,
    ROUND(100 * share_entire_homes, 1)                      AS pct_entire_homes,
    ROUND(CAST(median_price AS numeric), 0)                 AS median_price_eur,
    ROUND(CAST(median_rating AS numeric), 2)                AS median_rating,
    ROUND(est_revenue_12m / 1000000, 2)                     AS est_revenue_12m_eur_m
FROM mart.district_summary
ORDER BY density_rank;
