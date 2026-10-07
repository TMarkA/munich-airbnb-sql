-- 03 Median price by room type and size (normal nights only)

SELECT
    room_type,
    size_class,
    COUNT(*)                                                                    AS listings,
    ROUND(CAST(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price_normal_night) AS numeric)) AS median_price_eur,
    ROUND(CAST(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price_normal_night / accommodates) AS numeric)) AS median_price_per_guest_eur
FROM mart.listings
WHERE price_normal_night IS NOT NULL
GROUP BY room_type, size_class
HAVING COUNT(*) >= 20
ORDER BY room_type, size_class;
