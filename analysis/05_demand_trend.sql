-- 05 Reviews per year as demand proxy: growth and index (2019 = 100)
-- 2026 is a partial year, so Jan-Jun is compared separately

WITH yearly AS (
    SELECT
        d.year,
        COUNT(r.review_id)                                      AS reviews,
        COUNT(CASE WHEN d.month <= 6 THEN r.review_id END)      AS reviews_jan_jun,
        COUNT(DISTINCT r.listing_id)                            AS listings_reviewed
    FROM core.dim_date AS d
    LEFT JOIN core.fact_review AS r
           ON r.review_date = d.date
    WHERE d.year BETWEEN 2015 AND 2026
    GROUP BY d.year
)
SELECT
    year,
    year = (SELECT MAX(EXTRACT(YEAR FROM review_date)) FROM core.fact_review)        AS partial_year,
    reviews,
    ROUND(100.0 * reviews / LAG(reviews) OVER (ORDER BY year) - 100, 1)              AS yoy_growth_pct,
    ROUND(100.0 * reviews / (SELECT reviews FROM yearly WHERE year = 2019))          AS index_2019_100,
    reviews_jan_jun,
    ROUND(100.0 * reviews_jan_jun / LAG(reviews_jan_jun) OVER (ORDER BY year) - 100, 1) AS jan_jun_yoy_pct,
    listings_reviewed
FROM yearly
ORDER BY year;
