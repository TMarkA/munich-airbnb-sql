-- Date dimension: one row per day with Oktoberfest flag

DROP TABLE IF EXISTS core.dim_date CASCADE;

CREATE TABLE core.dim_date AS
SELECT
    CAST(d AS date)                          AS date,
    CAST(EXTRACT(YEAR FROM d) AS int)        AS year,
    CAST(EXTRACT(MONTH FROM d) AS int)       AS month,
    TO_CHAR(d, 'Mon')                        AS month_name,
    CAST(DATE_TRUNC('month', d) AS date)     AS month_start,
    TO_CHAR(d, 'Dy')                         AS weekday_name,
    TO_CHAR(d, 'Dy') IN ('Fri', 'Sat')       AS is_friday_or_saturday,
    o.year IS NOT NULL                       AS is_oktoberfest
FROM generate_series(
         (SELECT MIN(review_date) FROM stg.reviews),
         (SELECT MAX(night) FROM stg.calendar),
         INTERVAL '1 day') AS d
LEFT JOIN ref.oktoberfest AS o
       ON CAST(d AS date) BETWEEN o.start_date AND o.end_date;

ALTER TABLE core.dim_date ADD PRIMARY KEY (date);

COMMENT ON TABLE core.dim_date IS 'Calendar dimension (one row per day) with Oktoberfest flag';
COMMENT ON COLUMN core.dim_date.is_friday_or_saturday IS 'Nights from Friday or Saturday = weekend nights';
