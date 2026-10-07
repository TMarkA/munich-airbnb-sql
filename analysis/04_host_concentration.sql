-- 04 Share of listings and revenue by host type

WITH by_host_type AS (
    SELECT
        host_type,
        COUNT(DISTINCT host_id)                                          AS hosts,
        COUNT(*)                                                         AS listings,
        SUM(CASE WHEN is_active THEN 1 ELSE 0 END)                       AS active_listings,
        SUM(est_revenue)                                                 AS est_revenue,
        AVG(CASE WHEN room_type = 'Entire home/apt' THEN 1.0 ELSE 0.0 END) AS share_entire_homes,
        AVG(CASE WHEN is_active THEN est_nights_booked END)              AS avg_nights_active,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY rating_overall)      AS median_rating
    FROM mart.listings
    GROUP BY host_type
)
SELECT
    host_type,
    hosts,
    listings,
    ROUND(100.0 * listings / SUM(listings) OVER (), 1)                  AS pct_listings,
    ROUND(100.0 * active_listings / SUM(active_listings) OVER (), 1)    AS pct_active_listings,
    ROUND(100 * est_revenue / SUM(est_revenue) OVER (), 1)              AS pct_est_revenue,
    ROUND(100 * share_entire_homes, 1)                                  AS pct_entire_homes,
    ROUND(avg_nights_active)                                            AS avg_nights_booked_active,
    ROUND(CAST(median_rating AS numeric), 2)                            AS median_rating
FROM by_host_type
ORDER BY host_type;
