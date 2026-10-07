-- 10 Active entire homes above Munich's 56-night limit
-- estimate from reviews; some hosts hold permits

WITH entire_homes AS (
    SELECT host_type, exceeds_56_nights, est_nights_booked, est_revenue
    FROM mart.listings
    WHERE is_active
      AND room_type = 'Entire home/apt'
)
SELECT
    host_type,
    COUNT(*)                                                                    AS active_entire_homes,
    SUM(CASE WHEN exceeds_56_nights THEN 1 ELSE 0 END)                          AS above_56_nights,
    ROUND(100.0 * SUM(CASE WHEN exceeds_56_nights THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_above_56_nights,
    ROUND(AVG(CASE WHEN exceeds_56_nights THEN est_nights_booked END))          AS avg_nights_if_above,
    ROUND(100 * SUM(CASE WHEN exceeds_56_nights THEN est_revenue END) / SUM(est_revenue), 1) AS pct_revenue_from_above
FROM entire_homes
GROUP BY host_type

UNION ALL

SELECT
    'ALL HOSTS',
    COUNT(*),
    SUM(CASE WHEN exceeds_56_nights THEN 1 ELSE 0 END),
    ROUND(100.0 * SUM(CASE WHEN exceeds_56_nights THEN 1 ELSE 0 END) / COUNT(*), 1),
    ROUND(AVG(CASE WHEN exceeds_56_nights THEN est_nights_booked END)),
    ROUND(100 * SUM(CASE WHEN exceeds_56_nights THEN est_revenue END) / SUM(est_revenue), 1)
FROM entire_homes

ORDER BY host_type;
