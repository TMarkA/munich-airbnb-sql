-- 12 Returning guests: reviewers with more than one review

WITH per_reviewer AS (
    SELECT
        reviewer_id,
        COUNT(*)                                        AS reviews,
        COUNT(DISTINCT listing_id)                      AS listings,
        COUNT(DISTINCT EXTRACT(YEAR FROM review_date))  AS years_active,
        MAX(review_date) - MIN(review_date)             AS days_first_to_last
    FROM core.fact_review
    GROUP BY reviewer_id
)
SELECT
    COUNT(*)                                                                      AS reviewers,
    SUM(reviews)                                                                  AS reviews,
    ROUND(100.0 * SUM(CASE WHEN reviews >= 2 THEN 1 ELSE 0 END) / COUNT(*), 1)    AS pct_reviewed_twice_or_more,
    ROUND(100.0 * SUM(CASE WHEN reviews >= 2 THEN reviews ELSE 0 END) / SUM(reviews), 1) AS pct_reviews_from_returning,
    ROUND(100.0 * SUM(CASE WHEN reviews > listings THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_returned_to_same_listing,
    ROUND(100.0 * SUM(CASE WHEN years_active >= 2 THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_active_in_2plus_years,
    MAX(reviews)                                                                  AS most_reviews_by_one_guest,
    ROUND(AVG(CASE WHEN reviews >= 2 THEN days_first_to_last END))                AS avg_days_between_first_and_last
FROM per_reviewer;
