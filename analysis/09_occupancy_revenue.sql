-- 09 Active listings by booked nights: count and share of revenue

WITH active AS (
    SELECT
        *,
        CASE
            WHEN est_nights_booked <= 30  THEN '1 up to 30 nights'
            WHEN est_nights_booked <= 56  THEN '2 31-56 nights (within 8 weeks)'
            WHEN est_nights_booked <= 120 THEN '3 57-120 nights'
            WHEN est_nights_booked <= 200 THEN '4 121-200 nights'
            ELSE '5 more than 200 nights'
        END AS nights_band
    FROM mart.listings
    WHERE is_active
),
by_band AS (
    SELECT
        nights_band,
        COUNT(*)                                                                AS listings,
        AVG(CASE WHEN room_type = 'Entire home/apt' THEN 1.0 ELSE 0.0 END)      AS share_entire_homes,
        AVG(CASE WHEN host_type = '3 Professional (5+)' THEN 1.0 ELSE 0.0 END)  AS share_professional,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY est_revenue)                AS median_revenue,
        SUM(est_revenue)                                                        AS est_revenue
    FROM active
    GROUP BY nights_band
)
SELECT
    nights_band,
    listings,
    ROUND(100.0 * listings / SUM(listings) OVER (), 1)              AS pct_of_active,
    ROUND(100 * share_entire_homes, 1)                              AS pct_entire_homes,
    ROUND(100 * share_professional, 1)                              AS pct_professional_hosts,
    ROUND(CAST(median_revenue AS numeric))                          AS median_est_revenue_eur,
    ROUND(est_revenue / 1000000, 2)                                 AS est_revenue_eur_m,
    ROUND(100 * est_revenue / SUM(est_revenue) OVER (), 1)          AS pct_of_revenue
FROM by_band
ORDER BY nights_band;
