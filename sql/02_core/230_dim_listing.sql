-- Listing dimension: descriptive attributes

DROP TABLE IF EXISTS core.dim_listing CASCADE;

CREATE TABLE core.dim_listing AS
SELECT
    listing_id,
    listing_name,
    host_id,
    district,
    latitude,
    longitude,
    property_type,
    room_type,
    accommodates,
    CASE
        WHEN accommodates <= 2 THEN '1-2 guests'
        WHEN accommodates <= 4 THEN '3-4 guests'
        ELSE '5+ guests'
    END                         AS size_class,
    bedrooms,
    beds,
    bathrooms_text,
    has_wifi,
    has_kitchen,
    has_air_conditioning,
    first_review,
    last_review
FROM stg.listings;

ALTER TABLE core.dim_listing ADD PRIMARY KEY (listing_id);

ALTER TABLE core.dim_listing
    ADD FOREIGN KEY (host_id)  REFERENCES core.dim_host (host_id),
    ADD FOREIGN KEY (district) REFERENCES core.dim_district (district);

COMMENT ON TABLE core.dim_listing IS 'Descriptive attributes of each listing';
COMMENT ON COLUMN core.dim_listing.size_class IS 'Guests the listing accommodates: 1-2, 3-4, 5+';
