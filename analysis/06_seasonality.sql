-- 06 Seasonal index by month, 2023-2025

WITH monthly AS (
    SELECT d.year, d.month, d.month_name, COUNT(r.review_id) AS reviews
    FROM core.dim_date AS d
    LEFT JOIN core.fact_review AS r
           ON r.review_date = d.date
    WHERE d.year BETWEEN 2023 AND 2025
    GROUP BY d.year, d.month, d.month_name
)
SELECT
    month,
    month_name,
    ROUND(AVG(reviews))                                               AS avg_reviews,
    ROUND(100 * AVG(reviews) / AVG(AVG(reviews)) OVER ())             AS seasonal_index,
    MIN(reviews)                                                      AS min_year,
    MAX(reviews)                                                      AS max_year
FROM monthly
GROUP BY month, month_name
ORDER BY month;
