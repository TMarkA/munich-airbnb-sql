-- 08 Oktoberfest price premium: median quote for Oktoberfest vs other dates
-- compared within room type and size; different listings, so an estimate

WITH quotes AS (
    SELECT
        room_type,
        size_class,
        price_per_night,
        CASE WHEN quote_in_oktoberfest THEN 'oktoberfest' ELSE 'other dates' END AS period
    FROM mart.listings
    WHERE price_per_night IS NOT NULL
      AND NOT price_is_outlier
      AND room_type IN ('Entire home/apt', 'Private room')
),
-- add an 'all sizes' group per room type
quotes_with_total AS (
    SELECT room_type, size_class, price_per_night, period FROM quotes
    UNION ALL
    SELECT room_type, 'all sizes', price_per_night, period FROM quotes
),
medians AS (
    SELECT
        room_type,
        size_class,
        period,
        COUNT(*)                                                       AS quotes,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price_per_night)   AS median_price
    FROM quotes_with_total
    GROUP BY room_type, size_class, period
)
-- Oktoberfest and normal median side by side
SELECT
    okt.room_type,
    okt.size_class,
    okt.quotes                                                         AS quotes_oktoberfest,
    other.quotes                                                       AS quotes_other_dates,
    ROUND(CAST(other.median_price AS numeric))                         AS median_other_eur,
    ROUND(CAST(okt.median_price AS numeric))                           AS median_oktoberfest_eur,
    ROUND(CAST(100 * okt.median_price / other.median_price - 100 AS numeric)) AS premium_pct
FROM medians AS okt
JOIN medians AS other
  ON  other.room_type  = okt.room_type
  AND other.size_class = okt.size_class
  AND other.period     = 'other dates'
WHERE okt.period = 'oktoberfest'
  AND okt.quotes >= 10
ORDER BY okt.room_type, okt.size_class;
