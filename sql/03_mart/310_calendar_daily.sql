-- Share of unavailable listings per night and room type

DROP VIEW IF EXISTS mart.calendar_daily CASCADE;

CREATE VIEW mart.calendar_daily AS
SELECT
    c.night,
    d.weekday_name,
    d.is_friday_or_saturday,
    d.is_oktoberfest,
    l.room_type,
    COUNT(*)                                                 AS listings,
    AVG(CASE WHEN c.is_available THEN 0.0 ELSE 1.0 END)      AS share_unavailable
FROM core.fact_calendar AS c
JOIN core.dim_date      AS d ON d.date = c.night
JOIN core.dim_listing   AS l ON l.listing_id = c.listing_id
GROUP BY c.night, d.weekday_name, d.is_friday_or_saturday, d.is_oktoberfest, l.room_type;

COMMENT ON VIEW mart.calendar_daily IS 'Share of unavailable listings per future night and room type';
