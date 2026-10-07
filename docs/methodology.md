# Methodology

Every rule that changes a number between the Inside Airbnb files and the results, with the SQL file that implements it.

## 1. Data

[Inside Airbnb](https://insideairbnb.com/) scrapes the public Airbnb pages of a city every quarter. This project uses the **Munich snapshot of 29 June 2026**, scraped between 29 June and 2 July 2026.

| File | Rows | Grain |
|---|---|---|
| `listings.csv.gz` | 6,865 | one row per listing (price, host, location, ratings, …) |
| `calendar.csv.gz` | 2,514,850 | listing × night for the next 365 nights (bookable yes/no, minimum stay) |
| `reviews.csv.gz` | 237,201 | one row per review since 2011 |
| `neighbourhoods.geojson` | 25 | city district polygons |

**Privacy** ([`etl/prepare_data.py`](../etl/prepare_data.py)): host names, profile texts, photos and review texts are removed before the files are committed (GDPR principle of data minimisation). Numeric ids (listing, host, reviewer) are kept for joins.

## 2. Cleaning - [`sql/01_staging/`](../sql/01_staging/)

| Field | Raw | Clean |
|---|---|---|
| all columns | text, empty strings for missing values | `NULLIF(x, '')` turns empty text into NULL, `CAST(... AS type)` converts it |
| price | `"$1,234.50"` (the currency is EUR despite the `$`) | `1234.50` numeric, via `REPLACE` of `$` and `,` |
| amenities | list of ~50 strings such as `"Wifi"` | flags for Wifi, kitchen and air conditioning, via `LIKE` |
| district | `"Tudering-Riem"`, `"Obergiesing"` | official names *Trudering-Riem*, *Obergiesing-Fasangarten*, via a join to [`ref/districts.csv`](../ref/districts.csv) |
| booleans | `'t'` / `'f'` | `true` / `false` |

## 3. Key definitions

- **Active listing:** at least one review in the 12 months before the scrape (3,762 of 6,865).
- **Host type:** number of the host's listings in Munich: *single* (1), *multi* (2-4), *professional* (5+).
- **Price:** each listing's price is a **quote for one specific check-in date** (`quote_checkin`), not a list price. 168 quotes fall on Oktoberfest dates; they are flagged (`quote_in_oktoberfest`) and excluded from "normal" price statistics. Prices below €15 or above €2,000 are flagged as outliers. The column `price_normal_night` in `mart.listings` holds the price only when it is neither, and all median prices use it.
- **Oktoberfest dates** ([`010_ref_tables.sql`](../sql/00_setup/010_ref_tables.sql)) are the published dates 2011-2026, entered with `INSERT`. 2020 and 2021 were cancelled and are not in the table.

## 4. Estimated nights booked and revenue - [`300_listings.sql`](../sql/03_mart/300_listings.sql)

Airbnb does not publish bookings. Following Inside Airbnb's "San Francisco model":

```
nights booked (12 months) = reviews in the last 12 months / 0.5 (review rate)
                            × max(3, minimum stay)   (average length of stay)
                            capped at 255 nights (70% of the year)
revenue (12 months)       = nights booked × quoted price per night
```

The model is recomputed in SQL from the review table. It matches Inside Airbnb's own published estimate within 5 nights for 98% of listings (correlation 0.999), which is reported by the quality checks.

## 5. Calendar

`available = f` means a night is **booked or blocked** by the host; the data cannot separate the two. The share of unavailable nights is therefore an upper bound for occupancy. Comparisons between periods are still meaningful, because blocking behaviour does not change much from week to week.

## 6. Munich's 8-week rule

Under Munich's *Zweckentfremdungssatzung*, an entire home may be let to tourists for at most 8 weeks (56 nights) per calendar year without a permit; renting out rooms that make up less than half of a home is not restricted. `exceeds_56_nights` flags active entire homes whose estimated nights exceed 56. Because nights are estimated and some hosts hold permits, this measures **compliance risk, not violations**.

## 7. Limitations

- One snapshot: the market structure is a picture of June 2026. Demand history comes from review dates.
- Review rate and length of stay are assumptions of the occupancy model.
- The Oktoberfest price premium compares *different* listings quoted for different dates (within the same room type and size class), so it is an estimate, not a controlled experiment.
