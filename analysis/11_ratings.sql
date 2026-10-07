-- 11 Ratings by host type, superhost status and price band
-- ratings cluster near 5, so the share below 4.5 says more than the average

WITH rated AS (
    SELECT *
    FROM mart.listings
    WHERE rating_overall IS NOT NULL
      AND number_of_reviews >= 5
),
-- one block per breakdown
stacked AS (
    SELECT 'host type' AS dimension, host_type AS segment, rating_overall, rating_cleanliness, rating_value
    FROM rated
    UNION ALL
    SELECT 'superhost', CASE WHEN is_superhost THEN 'superhost' ELSE 'not superhost' END,
           rating_overall, rating_cleanliness, rating_value
    FROM rated
    UNION ALL
    SELECT 'price band', price_band, rating_overall, rating_cleanliness, rating_value
    FROM rated
    WHERE price_band IS NOT NULL
    UNION ALL
    SELECT 'all', 'all listings (>= 5 reviews)', rating_overall, rating_cleanliness, rating_value
    FROM rated
)
SELECT
    dimension,
    segment,
    COUNT(*)                                                               AS listings,
    ROUND(AVG(rating_overall), 2)                                          AS avg_rating,
    ROUND(100 * AVG(CASE WHEN rating_overall < 4.5 THEN 1.0 ELSE 0.0 END), 1)  AS pct_below_4_5,
    ROUND(100 * AVG(CASE WHEN rating_overall >= 4.9 THEN 1.0 ELSE 0.0 END), 1) AS pct_4_9_or_better,
    ROUND(AVG(rating_cleanliness), 2)                                      AS avg_cleanliness,
    ROUND(AVG(rating_value), 2)                                            AS avg_value_for_money
FROM stacked
GROUP BY dimension, segment
ORDER BY
    CASE dimension
        WHEN 'all'        THEN 1
        WHEN 'host type'  THEN 2
        WHEN 'superhost'  THEN 3
        WHEN 'price band' THEN 4
    END,
    segment;
