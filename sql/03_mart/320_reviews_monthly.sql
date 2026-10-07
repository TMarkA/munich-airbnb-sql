-- Reviews per month (months without reviews included), last year and rolling 12 months

DROP VIEW IF EXISTS mart.reviews_monthly CASCADE;

CREATE VIEW mart.reviews_monthly AS
WITH months AS (
    SELECT DISTINCT month_start
    FROM core.dim_date
    WHERE month_start <= (SELECT MAX(review_date) FROM core.fact_review)
),
monthly AS (
    SELECT
        CAST(DATE_TRUNC('month', review_date) AS date) AS month_start,
        COUNT(*)                                AS reviews,
        COUNT(DISTINCT listing_id)              AS listings_reviewed,
        COUNT(DISTINCT reviewer_id)             AS reviewers
    FROM core.fact_review
    GROUP BY CAST(DATE_TRUNC('month', review_date) AS date)
)
SELECT
    m.month_start,
    COALESCE(x.reviews, 0)              AS reviews,
    COALESCE(x.listings_reviewed, 0)    AS listings_reviewed,
    COALESCE(x.reviewers, 0)            AS reviewers,
    ly.reviews                          AS reviews_same_month_last_year,
    SUM(COALESCE(x.reviews, 0)) OVER (ORDER BY m.month_start
                                      ROWS BETWEEN 11 PRECEDING AND CURRENT ROW) AS reviews_rolling_12m
FROM months AS m
LEFT JOIN monthly AS x  ON x.month_start  = m.month_start
LEFT JOIN monthly AS ly ON ly.month_start = CAST(m.month_start - INTERVAL '1 year' AS date);

COMMENT ON VIEW mart.reviews_monthly IS 'Reviews per month with same month last year and a rolling 12-month total';
