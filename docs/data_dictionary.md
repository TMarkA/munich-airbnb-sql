# Data dictionary

_Generated from the database catalog by `python pipeline.py docs` - do not edit by hand._

## Schema `core`

### `core.dim_date` (table)

Calendar dimension (one row per day) with Oktoberfest flag

| # | Column | Type | Description |
|---|---|---|---|
| 1 | `date` | date |  |
| 2 | `year` | integer |  |
| 3 | `month` | integer |  |
| 4 | `month_name` | text |  |
| 5 | `month_start` | date |  |
| 6 | `weekday_name` | text |  |
| 7 | `is_friday_or_saturday` | boolean | Nights from Friday or Saturday = weekend nights |
| 8 | `is_oktoberfest` | boolean |  |

### `core.dim_district` (table)

City districts with area in km² (computed from the GeoJSON) and polygon

| # | Column | Type | Description |
|---|---|---|---|
| 1 | `district` | text |  |
| 2 | `district_no` | smallint |  |
| 3 | `area_km2` | numeric |  |
| 4 | `geometry` | text |  |

### `core.dim_host` (table)

One row per host with host type (single / multi / professional)

| # | Column | Type | Description |
|---|---|---|---|
| 1 | `host_id` | bigint |  |
| 2 | `is_superhost` | boolean |  |
| 3 | `listings_in_munich` | integer |  |
| 4 | `host_type` | text | 1 Single listing / 2 Multi (2-4) / 3 Professional (5+ listings in Munich) |

### `core.dim_listing` (table)

Descriptive attributes of each listing

| # | Column | Type | Description |
|---|---|---|---|
| 1 | `listing_id` | bigint |  |
| 2 | `listing_name` | text |  |
| 3 | `host_id` | bigint |  |
| 4 | `district` | text |  |
| 5 | `latitude` | numeric |  |
| 6 | `longitude` | numeric |  |
| 7 | `property_type` | text |  |
| 8 | `room_type` | text |  |
| 9 | `accommodates` | integer |  |
| 10 | `size_class` | text | Guests the listing accommodates: 1-2, 3-4, 5+ |
| 11 | `bedrooms` | integer |  |
| 12 | `beds` | integer |  |
| 13 | `bathrooms_text` | text |  |
| 14 | `has_wifi` | boolean |  |
| 15 | `has_kitchen` | boolean |  |
| 16 | `has_air_conditioning` | boolean |  |
| 17 | `first_review` | date |  |
| 18 | `last_review` | date |  |

### `core.fact_calendar` (table)

Bookability of every listing for each of the next 365 nights

| # | Column | Type | Description |
|---|---|---|---|
| 1 | `listing_id` | bigint |  |
| 2 | `night` | date |  |
| 3 | `is_available` | boolean | true = still bookable; false = booked or blocked by the host |
| 4 | `minimum_nights` | integer |  |

### `core.fact_listing_snapshot` (table)

Price quote, availability, review count and ratings of each listing on the scrape date

| # | Column | Type | Description |
|---|---|---|---|
| 1 | `listing_id` | bigint |  |
| 2 | `snapshot_date` | date | First day of the scrape (29 June 2026) |
| 3 | `price_per_night` | numeric | Quoted price per night in EUR for quote_checkin (not a list price) |
| 4 | `price_is_outlier` | boolean |  |
| 5 | `quote_checkin` | date |  |
| 6 | `quote_in_oktoberfest` | boolean | The price quote is for a check-in during Oktoberfest |
| 7 | `minimum_nights` | integer |  |
| 8 | `availability_365` | integer |  |
| 9 | `number_of_reviews` | integer |  |
| 10 | `rating_overall` | numeric |  |
| 11 | `rating_cleanliness` | numeric |  |
| 12 | `rating_location` | numeric |  |
| 13 | `rating_value` | numeric |  |
| 14 | `ia_estimated_nights` | integer | Inside Airbnb's own estimate of nights booked in the last 365 days |
| 15 | `ia_estimated_revenue` | numeric |  |

### `core.fact_review` (table)

Every review (date, listing, pseudonymous reviewer id); text removed for privacy

| # | Column | Type | Description |
|---|---|---|---|
| 1 | `review_id` | bigint |  |
| 2 | `listing_id` | bigint |  |
| 3 | `reviewer_id` | bigint |  |
| 4 | `review_date` | date |  |
| 5 | `listing_exists` | boolean | false if the listing has since left Airbnb (review kept as past demand) |

## Schema `mart`

### `mart.calendar_daily` (view)

Share of unavailable listings per future night and room type

| # | Column | Type | Description |
|---|---|---|---|
| 1 | `night` | date |  |
| 2 | `weekday_name` | text |  |
| 3 | `is_friday_or_saturday` | boolean |  |
| 4 | `is_oktoberfest` | boolean |  |
| 5 | `room_type` | text |  |
| 6 | `listings` | bigint |  |
| 7 | `share_unavailable` | numeric |  |

### `mart.district_summary` (view)

Listings, density, median price and estimated revenue per district

| # | Column | Type | Description |
|---|---|---|---|
| 1 | `district` | text |  |
| 2 | `area_km2` | numeric |  |
| 3 | `listings` | bigint |  |
| 4 | `active_listings` | bigint |  |
| 5 | `listings_per_km2` | numeric |  |
| 6 | `share_entire_homes` | numeric |  |
| 7 | `median_price` | double precision |  |
| 8 | `median_rating` | double precision |  |
| 9 | `est_revenue_12m` | numeric |  |

### `mart.listings` (view)

One row per listing with host, district, price and occupancy estimates

| # | Column | Type | Description |
|---|---|---|---|
| 1 | `listing_id` | bigint |  |
| 2 | `listing_name` | text |  |
| 3 | `district` | text |  |
| 4 | `latitude` | numeric |  |
| 5 | `longitude` | numeric |  |
| 6 | `property_type` | text |  |
| 7 | `room_type` | text |  |
| 8 | `size_class` | text |  |
| 9 | `accommodates` | integer |  |
| 10 | `bedrooms` | integer |  |
| 11 | `beds` | integer |  |
| 12 | `has_air_conditioning` | boolean |  |
| 13 | `host_id` | bigint |  |
| 14 | `host_type` | text |  |
| 15 | `is_superhost` | boolean |  |
| 16 | `price_per_night` | numeric |  |
| 17 | `price_is_outlier` | boolean |  |
| 18 | `quote_checkin` | date |  |
| 19 | `quote_in_oktoberfest` | boolean |  |
| 20 | `minimum_nights` | integer |  |
| 21 | `availability_365` | integer |  |
| 22 | `number_of_reviews` | integer |  |
| 23 | `rating_overall` | numeric |  |
| 24 | `rating_cleanliness` | numeric |  |
| 25 | `rating_location` | numeric |  |
| 26 | `rating_value` | numeric |  |
| 27 | `first_review` | date |  |
| 28 | `last_review` | date |  |
| 29 | `reviews_12m` | bigint |  |
| 30 | `est_nights_booked` | integer | Estimated nights booked in the last 12 months (San Francisco model, from reviews) |
| 31 | `ia_estimated_nights` | integer |  |
| 32 | `ia_estimated_revenue` | numeric |  |
| 33 | `is_active` | boolean | At least one review in the 12 months before the scrape |
| 34 | `est_revenue` | numeric |  |
| 35 | `price_normal_night` | numeric | Price for statistics: NULL for outliers and for quotes on Oktoberfest dates |
| 36 | `exceeds_56_nights` | boolean | Entire home with more than 56 estimated nights: above Munich's 8-week limit without permit |
| 37 | `price_band` | text |  |

### `mart.reviews_monthly` (view)

Reviews per month with same month last year and a rolling 12-month total

| # | Column | Type | Description |
|---|---|---|---|
| 1 | `month_start` | date |  |
| 2 | `reviews` | bigint |  |
| 3 | `listings_reviewed` | bigint |  |
| 4 | `reviewers` | bigint |  |
| 5 | `reviews_same_month_last_year` | bigint |  |
| 6 | `reviews_rolling_12m` | numeric |  |

## Schema `stg`

### `stg.calendar` (table)

| # | Column | Type | Description |
|---|---|---|---|
| 1 | `listing_id` | bigint |  |
| 2 | `night` | date |  |
| 3 | `is_available` | boolean |  |
| 4 | `minimum_nights` | integer |  |

### `stg.listings` (table)

Typed and cleaned listings; price = quote for the date quote_checkin

| # | Column | Type | Description |
|---|---|---|---|
| 1 | `listing_id` | bigint |  |
| 2 | `listing_name` | text |  |
| 3 | `host_id` | bigint |  |
| 4 | `host_is_superhost` | boolean |  |
| 5 | `host_listings_in_munich` | integer |  |
| 6 | `district` | text |  |
| 7 | `latitude` | numeric |  |
| 8 | `longitude` | numeric |  |
| 9 | `property_type` | text |  |
| 10 | `room_type` | text |  |
| 11 | `accommodates` | integer |  |
| 12 | `bathrooms_text` | text |  |
| 13 | `bedrooms` | integer |  |
| 14 | `beds` | integer |  |
| 15 | `has_wifi` | boolean |  |
| 16 | `has_kitchen` | boolean |  |
| 17 | `has_air_conditioning` | boolean |  |
| 18 | `price_per_night` | numeric |  |
| 19 | `quote_checkin` | date |  |
| 20 | `minimum_nights` | integer |  |
| 21 | `availability_365` | integer |  |
| 22 | `number_of_reviews` | integer |  |
| 23 | `first_review` | date |  |
| 24 | `last_review` | date |  |
| 25 | `rating_overall` | numeric |  |
| 26 | `rating_cleanliness` | numeric |  |
| 27 | `rating_location` | numeric |  |
| 28 | `rating_value` | numeric |  |
| 29 | `ia_estimated_nights` | integer |  |
| 30 | `ia_estimated_revenue` | numeric |  |
| 31 | `last_scraped` | date |  |

### `stg.reviews` (table)

| # | Column | Type | Description |
|---|---|---|---|
| 1 | `review_id` | bigint |  |
| 2 | `listing_id` | bigint |  |
| 3 | `reviewer_id` | bigint |  |
| 4 | `review_date` | date |  |

## Schema `ref`

### `ref.districts` (table)

Official names and numbers of the 25 city districts

| # | Column | Type | Description |
|---|---|---|---|
| 1 | `district_no` | smallint |  |
| 2 | `district` | text |  |
| 3 | `source_name` | text |  |

### `ref.oktoberfest` (table)

Published Oktoberfest dates (2020 and 2021 cancelled)

| # | Column | Type | Description |
|---|---|---|---|
| 1 | `year` | integer |  |
| 2 | `start_date` | date |  |
| 3 | `end_date` | date |  |
