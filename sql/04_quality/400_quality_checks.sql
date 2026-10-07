-- Data-quality checks: 'must be 0' = error, 'info' = known property of the data

SELECT 'duplicate listing ids' AS check_name,
       COUNT(*) - COUNT(DISTINCT id) AS problem_rows,
       COUNT(*) AS checked_rows,
       'must be 0' AS rule
FROM raw.listings;

SELECT 'listings without an official district' AS check_name,
       SUM(CASE WHEN r.district IS NULL THEN 1 ELSE 0 END) AS problem_rows,
       COUNT(*) AS checked_rows,
       'must be 0' AS rule
FROM core.dim_listing AS l
LEFT JOIN ref.districts AS r ON r.district = l.district;

SELECT 'prices that could not be converted' AS check_name,
       SUM(CASE WHEN s.price_per_night IS NULL THEN 1 ELSE 0 END) AS problem_rows,
       COUNT(*) AS checked_rows,
       'must be 0' AS rule
FROM raw.listings AS r
JOIN stg.listings AS s ON s.listing_id = CAST(r.id AS bigint)
WHERE r.price <> '';

SELECT 'coordinates outside Munich' AS check_name,
       SUM(CASE WHEN latitude NOT BETWEEN 48.06 AND 48.25
                  OR longitude NOT BETWEEN 11.36 AND 11.73 THEN 1 ELSE 0 END) AS problem_rows,
       COUNT(*) AS checked_rows,
       'must be 0' AS rule
FROM core.dim_listing;

SELECT 'ratings outside 0-5' AS check_name,
       SUM(CASE WHEN rating_overall NOT BETWEEN 0 AND 5 THEN 1 ELSE 0 END) AS problem_rows,
       COUNT(rating_overall) AS checked_rows,
       'must be 0' AS rule
FROM core.fact_listing_snapshot;

SELECT 'reviews dated after the scrape' AS check_name,
       SUM(CASE WHEN review_date > (SELECT MAX(last_scraped) FROM stg.listings) THEN 1 ELSE 0 END) AS problem_rows,
       COUNT(*) AS checked_rows,
       'must be 0' AS rule
FROM core.fact_review;

SELECT 'listings without a price' AS check_name,
       SUM(CASE WHEN price_per_night IS NULL THEN 1 ELSE 0 END) AS problem_rows,
       COUNT(*) AS checked_rows,
       'info' AS rule
FROM core.fact_listing_snapshot;

SELECT 'price outliers (under 15 or over 2,000 EUR)' AS check_name,
       SUM(CASE WHEN price_is_outlier THEN 1 ELSE 0 END) AS problem_rows,
       COUNT(price_per_night) AS checked_rows,
       'info' AS rule
FROM core.fact_listing_snapshot;

SELECT 'calendar listings missing in the listings file' AS check_name,
       COUNT(DISTINCT CASE WHEN l.listing_id IS NULL THEN c.listing_id END) AS problem_rows,
       COUNT(DISTINCT c.listing_id) AS checked_rows,
       'info' AS rule
FROM stg.calendar AS c
LEFT JOIN core.dim_listing AS l ON l.listing_id = c.listing_id;

SELECT 'reviews of listings that left Airbnb' AS check_name,
       SUM(CASE WHEN NOT listing_exists THEN 1 ELSE 0 END) AS problem_rows,
       COUNT(*) AS checked_rows,
       'info' AS rule
FROM core.fact_review;

SELECT 'occupancy estimate differs from Inside Airbnb by more than 5 nights' AS check_name,
       SUM(CASE WHEN ABS(est_nights_booked - ia_estimated_nights) > 5 THEN 1 ELSE 0 END) AS problem_rows,
       COUNT(*) AS checked_rows,
       'info' AS rule
FROM mart.listings;

SELECT 'listings with fewer than 360 calendar nights' AS check_name,
       (SELECT COUNT(*)
        FROM (SELECT listing_id
              FROM core.fact_calendar
              GROUP BY listing_id
              HAVING COUNT(*) < 360) AS short_calendars) AS problem_rows,
       (SELECT COUNT(*) FROM core.dim_listing) AS checked_rows,
       'info' AS rule;
