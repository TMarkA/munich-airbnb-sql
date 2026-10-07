-- 07 Share of nights already taken around Oktoberfest 2026 (calendar scraped 29 June 2026)

WITH nights AS (
    SELECT
        c.night,
        l.room_type,
        c.is_available,
        CASE
            WHEN c.night BETWEEN o.start_date AND o.end_date           THEN '2 Oktoberfest (19 Sep - 4 Oct)'
            WHEN c.night BETWEEN o.start_date - 28 AND o.start_date - 1 THEN '1 four weeks before'
            WHEN c.night BETWEEN o.end_date + 1 AND o.end_date + 28     THEN '3 four weeks after'
        END AS period
    FROM core.fact_calendar AS c
    JOIN core.dim_listing AS l
      ON l.listing_id = c.listing_id
    CROSS JOIN ref.oktoberfest AS o
    WHERE o.year = 2026
)
SELECT
    period,
    COUNT(DISTINCT night)                                                          AS nights,
    ROUND(100.0 * SUM(CASE WHEN NOT is_available THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_unavailable_all,
    ROUND(100.0 * SUM(CASE WHEN room_type = 'Entire home/apt' AND NOT is_available THEN 1 ELSE 0 END)
                / SUM(CASE WHEN room_type = 'Entire home/apt' THEN 1 ELSE 0 END), 1) AS pct_unavailable_entire_homes,
    ROUND(100.0 * SUM(CASE WHEN room_type = 'Private room' AND NOT is_available THEN 1 ELSE 0 END)
                / SUM(CASE WHEN room_type = 'Private room' THEN 1 ELSE 0 END), 1)    AS pct_unavailable_private_rooms
FROM nights
WHERE period IS NOT NULL
GROUP BY period
ORDER BY period;
